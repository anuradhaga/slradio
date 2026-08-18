import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';
import 'favorites_service.dart';

class RadioAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  RadioAudioHandler() {
    // Initialize favorites and queue immediately using default fallback stations,
    // and set up listeners for dynamic changes.
    FavoritesService().initialize().then((_) {
      _updateQueue();
      FavoritesService().favorites.addListener(_updateQueue);
      RadioStation.stationsNotifier.addListener(_updateQueue);
    });

    // Start background load of remote config
    RadioStation.loadStations();

    // Listen to playback event changes and update state
    _player.playbackEventStream.listen((event) {
      _updatePlaybackState();
    });

    // Listen to mediaItem changes and update state
    mediaItem.listen((item) {
      _updatePlaybackState();
    });

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

  // Populate the queue with all available stations
  void _updateQueue() {
    final List<MediaItem> items = [];
    final favList = FavoritesService().favorites.value;

    for (final station in RadioStation.stations) {
      final artUri = _getArtworkUri(station);
      final isFav = favList.contains(station.id);
      items.add(MediaItem(
        id: station.id,
        album: station.frequency,
        title: station.name,
        artist: station.description,
        artUri: artUri,
        rating: Rating.newHeartRating(isFav),
        isLive: true,
        playable: true,
      ));
    }
    queue.add(items);
  }

  // Update PlaybackState based on the current player and queue state
  void _updatePlaybackState() {
    final currentItem = mediaItem.value;
    final currentId = currentItem?.id;
    final isFav = currentId != null && FavoritesService().isFavorite(currentId);
    final queueList = queue.hasValue ? queue.value : <MediaItem>[];
    final int? activeIndex = currentId != null && queueList.isNotEmpty
        ? queueList.indexWhere((item) => item.id == currentId)
        : null;

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
        // Surfaces add to favorites directly on Android Auto Now Playing screen
        MediaControl(
          androidIcon: isFav ? 'drawable/ic_favorite' : 'drawable/ic_favorite_border',
          label: isFav ? 'Remove Favorite' : 'Add Favorite',
          action: MediaAction.custom,
          customAction: const CustomMediaAction(
            name: 'toggle_favorite',
          ),
        ),
      ],
      systemActions: const {
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
      queueIndex: (activeIndex != null && activeIndex != -1) ? activeIndex : null,
    ));
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final queueList = queue.hasValue ? queue.value : <MediaItem>[];
    if (index >= 0 && index < queueList.length) {
      await playFromMediaId(queueList[index].id);
    }
  }

  // Helper to return hosted network logo URL
  Uri? _getArtworkUri(RadioStation station) {
    if (station.logoUrl != null) {
      return Uri.parse(station.logoUrl!);
    }
    return null;
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

  /// Handles custom actions sent from clients (like our custom favorite toggle button).
  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'toggle_favorite') {
      final current = mediaItem.value;
      if (current == null) return;
      await FavoritesService().toggleFavorite(current.id);
      
      // Update the rating state on MediaItem (standard rating path)
      final isFav = FavoritesService().isFavorite(current.id);
      final updatedItem = current.copyWith(rating: Rating.newHeartRating(isFav));
      mediaItem.add(updatedItem);
    }
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    // Find the station
    final station = RadioStation.stations.firstWhere((s) => s.id == mediaId);
    
    // 1. Immediately push basic MediaItem to the system (instant response to Android Auto).
    //    Include the heart rating and mark it as a live stream to let Android Auto render it correctly.
    await FavoritesService().initialize();
    final initialItem = MediaItem(
      id: station.id,
      album: station.frequency,
      title: station.name,
      artist: station.description,
      artUri: station.logoUrl != null ? Uri.parse(station.logoUrl!) : null,
      rating: Rating.newHeartRating(FavoritesService().isFavorite(station.id)),
      isLive: true,
    );
    mediaItem.add(initialItem);

    // 2. Start playback in the background (non-blocking to prevent Android Auto timeouts)
    //    Using preload: false ensures setAudioSource returns immediately, and calling play()
    //    instantly transitions the player to the playing (buffering) state.
    _player.setAudioSource(
      AudioSource.uri(Uri.parse(station.streamUrl)),
      preload: false,
    ).then((_) {
      // Playback already initiated or ready
    }).catchError((e) {
      playbackState.add(playbackState.value.copyWith(
        errorMessage: e.toString(),
      ));
    });
    _player.play();

    // 3. Resolve local artwork URI synchronously and update MediaItem
    final artUri = _getArtworkUri(station);
    if (artUri != null) {
      mediaItem.add(initialItem.copyWith(artUri: artUri, isLive: true));
    }
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    try {
      final station = RadioStation.stations.firstWhere((s) => s.id == mediaId);
      await FavoritesService().initialize();
      final artUri = _getArtworkUri(station);
      return MediaItem(
        id: station.id,
        album: station.frequency,
        title: station.name,
        artist: station.description,
        artUri: artUri,
        rating: Rating.newHeartRating(FavoritesService().isFavorite(station.id)),
        isLive: true,
        playable: true,
      );
    } catch (_) {
      return null;
    }
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
      await FavoritesService().initialize();
      final favList = FavoritesService().favorites.value;

      for (final station in RadioStation.stations) {
        final artUri = _getArtworkUri(station);
        final isFav = favList.contains(station.id);
        items.add(MediaItem(
          id: station.id,
          album: station.frequency,
          title: isFav ? '❤️ ${station.name}' : station.name,
          artist: null, // No tagline in browsing list
          artUri: artUri,
          isLive: true,
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
          final artUri = _getArtworkUri(station);
          items.add(MediaItem(
            id: station.id,
            album: station.frequency,
            title: '❤️ ${station.name}',
            artist: null, // No tagline in browsing list
            artUri: artUri,
            isLive: true,
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
        final artUri = _getArtworkUri(station);
        await FavoritesService().initialize();
        final isFav = FavoritesService().isFavorite(station.id);
        return [
          MediaItem(
            id: station.id,
            album: station.frequency,
            title: isFav ? '❤️ ${station.name}' : station.name,
            artist: station.description,
            artUri: artUri,
            rating: Rating.newHeartRating(isFav),
            isLive: true,
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
