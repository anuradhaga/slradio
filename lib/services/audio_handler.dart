import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';
import 'favorites_service.dart';

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
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        // Tells Android Auto / media session to expose a heart/rating button
        MediaAction.setRating,
      },
      androidCompactActionIndices: const [0, 1, 3],
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

  /// Called by Android Auto when the user taps the heart/rating button.
  /// Toggles the current station's favorite status and refreshes the
  /// MediaItem rating so Android Auto updates the heart icon.
  @override
  Future<void> setRating(Rating rating, [Map<String, dynamic>? extras]) async {
    final current = mediaItem.value;
    if (current == null) return;
    await FavoritesService().toggleFavorite(current.id);
    // Update the MediaItem rating so Android Auto refreshes the heart icon
    // (Rating lives on MediaItem in audio_service 0.18.x, not PlaybackState)
    final isFav = FavoritesService().isFavorite(current.id);
    mediaItem.add(current.copyWith(rating: Rating.newHeartRating(isFav)));
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    // Find the station
    final station = RadioStation.stations.firstWhere((s) => s.id == mediaId);
    
    // 1. Immediately push basic MediaItem to the system (instant response to Android Auto).
    //    Include the heart rating so Android Auto shows the correct state from the start.
    await FavoritesService().initialize();
    final initialItem = MediaItem(
      id: station.id,
      album: station.frequency,
      title: station.name,
      artist: station.description,
      artUri: station.logoUrl != null ? Uri.parse(station.logoUrl!) : null,
      rating: Rating.newHeartRating(FavoritesService().isFavorite(station.id)),
    );
    mediaItem.add(initialItem);

    // 2. Start playback in the background (non-blocking to prevent Android Auto timeouts)
    _player.stop().then((_) {
      return _player.setAudioSource(AudioSource.uri(Uri.parse(station.streamUrl)));
    }).then((_) {
      _player.play();
    }).catchError((e) {
      playbackState.add(playbackState.value.copyWith(
        errorMessage: e.toString(),
      ));
    });

    // 3. Resolve local artwork URI asynchronously in the background
    _getArtworkUri(station).then((artUri) {
      if (artUri != null && mediaItem.value?.id == station.id) {
        mediaItem.add(initialItem.copyWith(artUri: artUri));
      }
    }).catchError((_) {
      // Ignore artwork errors
    });
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) async {
    if (parentMediaId == AudioService.browsableRootId) {
      return [
        const MediaItem(
          id: 'favorites_folder',
          title: '★ My Favorites',
          album: 'Folder',
          playable: false,
        ),
        const MediaItem(
          id: 'all_stations_folder',
          title: '📻 All Online Stations',
          album: 'Folder',
          playable: false,
        ),
      ];
    } else if (parentMediaId == 'all_stations_folder') {
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
    } else if (parentMediaId == 'favorites_folder') {
      final List<MediaItem> items = [];
      // Make sure favorites are loaded
      await FavoritesService().initialize();
      final favList = FavoritesService().favorites.value;
      
      for (final station in RadioStation.stations) {
        if (favList.contains(station.id)) {
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
      }
      return items;
    } else {
      // Android Auto calls getChildren(stationId) after the user taps a
      // playable item to render the Now Playing screen. Return the station's
      // own MediaItem so the screen can load successfully.
      try {
        final station = RadioStation.stations.firstWhere((s) => s.id == parentMediaId);
        final artUri = await _getArtworkUri(station);
        return [
          MediaItem(
            id: station.id,
            album: station.frequency,
            title: station.name,
            artist: station.description,
            artUri: artUri,
            playable: true,
          ),
        ];
      } catch (_) {
        // parentMediaId is not a known station — return empty
      }
    }
    return [];
  }

  @override
  Future<void> skipToNext() async {
    final current = mediaItem.value;
    if (current == null) return;
    final index = RadioStation.stations.indexWhere((s) => s.id == current.id);
    if (index != -1) {
      final nextIndex = (index + 1) % RadioStation.stations.length;
      final nextStation = RadioStation.stations[nextIndex];
      await playFromMediaId(nextStation.id);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final current = mediaItem.value;
    if (current == null) return;
    final index = RadioStation.stations.indexWhere((s) => s.id == current.id);
    if (index != -1) {
      final prevIndex = (index - 1 + RadioStation.stations.length) % RadioStation.stations.length;
      final prevStation = RadioStation.stations[prevIndex];
      await playFromMediaId(prevStation.id);
    }
  }
}

late RadioAudioHandler audioHandler;
