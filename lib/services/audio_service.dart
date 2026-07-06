import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/station.dart';
import 'audio_handler.dart';

class RadioAudioService {
  // Singleton pattern
  static final RadioAudioService _instance = RadioAudioService._internal();
  factory RadioAudioService() => _instance;

  final ValueNotifier<RadioStation?> _currentStation = ValueNotifier<RadioStation?>(null);
  bool _isInitialized = false;

  RadioAudioService._internal();

  // Getters delegating to global audioHandler/player
  AudioPlayer get player => audioHandler.player;
  ValueListenable<RadioStation?> get currentStation => _currentStation;
  
  Stream<PlayerState> get playerStateStream => audioHandler.player.playerStateStream;
  Stream<Duration?> get durationStream => audioHandler.player.durationStream;
  Stream<Duration> get positionStream => audioHandler.player.positionStream;
  Stream<Duration> get bufferedPositionStream => audioHandler.player.bufferedPositionStream;
  Stream<double> get volumeStream => audioHandler.player.volumeStream;

  // Stream for current track title parsed from mediaItem stream (which updates from ICY metadata)
  Stream<String?> get trackMetadataStream => audioHandler.mediaItem.map((item) {
    if (item == null) return null;
    // If the title is not the station name, we assume it's live track metadata
    final station = RadioStation.stations.firstWhere((s) => s.id == item.id);
    if (item.title != station.name) {
      return item.title;
    }
    return null;
  });

  // Initialization
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set up audio session for background playback and system audio focus
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to interruptions (calls, navigations, headphone unplugged)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
          case AudioInterruptionType.duck:
            // Lower volume
            audioHandler.player.setVolume(0.2);
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // Don't resume automatically unless desired
            break;
          case AudioInterruptionType.duck:
            audioHandler.player.setVolume(1.0);
            break;
        }
      }
    });

    // Pause on headphone unplug (Becomes noisy / speaker output prevention)
    session.becomingNoisyEventStream.listen((_) {
      pause();
    });

    // Listen to mediaItem changes from the global AudioHandler
    // and automatically update currentStation for UI bindings
    audioHandler.mediaItem.listen((item) {
      if (item == null) {
        _currentStation.value = null;
      } else {
        try {
          _currentStation.value = RadioStation.stations.firstWhere((s) => s.id == item.id);
        } catch (_) {
          _currentStation.value = null;
        }
      }
    });

    _isInitialized = true;
  }

  // Play a specific station
  Future<void> playStation(RadioStation station) async {
    await initialize();

    if (_currentStation.value?.id == station.id && audioHandler.player.playing) {
      // Already playing this station
      return;
    }

    await audioHandler.playFromMediaId(station.id);
  }

  // Controls
  Future<void> play() async {
    if (_currentStation.value != null) {
      await audioHandler.play();
    }
  }

  Future<void> pause() async {
    await audioHandler.pause();
  }

  Future<void> stop() async {
    await audioHandler.stop();
  }

  Future<void> togglePlay() async {
    if (audioHandler.player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> setVolume(double value) async {
    await audioHandler.player.setVolume(value.clamp(0.0, 1.0));
  }

  // Cleanup
  Future<void> dispose() async {
    // Shared AudioHandler is managed globally
  }
}
