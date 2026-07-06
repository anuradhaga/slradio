import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';

class RadioAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  RadioAudioHandler() {
    // Forward playback events from just_audio to audio_service
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Watch for current station metadata changes (ICY metadata)
    _player.icyMetadataStream.listen((metadata) {
      if (metadata == null) return;
      final title = metadata.info?.title;
      if (title != null && title.trim().isNotEmpty) {
        final current = mediaItem.value;
        if (current != null) {
          mediaItem.add(current.copyWith(
            title: title.trim(),
            artist: current.artist ?? 'Live Stream',
          ));
        }
      }
    });
  }

  // Get raw player access for simple bindings in wrapper
  AudioPlayer get player => _player;

  // Convert just_audio events to audio_service PlaybackState
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.stop,
        if (_player.playing) MediaControl.pause else MediaControl.play,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // Helper to copy local assets to temporary directory for system notifications
  Future<Uri?> _getArtworkUri(RadioStation station) async {
    if (station.logoAsset != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${station.id}_logo.jpg');
        // Cache check
        if (await file.exists()) {
          return file.uri;
        }
        // Write to temp file
        final byteData = await rootBundle.load(station.logoAsset!);
        await file.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
        return file.uri;
      } catch (e) {
        // Fallback to logoUrl if error occurs
      }
    }
    return station.logoUrl != null ? Uri.parse(station.logoUrl!) : null;
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    // Find the station
    final station = RadioStation.stations.firstWhere((s) => s.id == mediaId);
    
    // Resolve local artwork URI if available
    final artUri = await _getArtworkUri(station);

    // Create MediaItem for current playback
    final item = MediaItem(
      id: station.id,
      album: station.frequency,
      title: station.name,
      artist: station.description,
      artUri: artUri,
    );
    mediaItem.add(item);

    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(station.streamUrl)));
      await _player.play();
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) async {
    if (parentMediaId == AudioService.browsableRootId) {
      final List<MediaItem> items = [];
      for (final station in RadioStation.stations) {
        final artUri = await _getArtworkUri(station);
        items.add(MediaItem(
          id: station.id,
          album: station.frequency,
          title: station.name,
          artist: station.description,
          artUri: artUri,
          playable: true,
        ));
      }
      return items;
    }
    return [];
  }
}

late RadioAudioHandler audioHandler;
