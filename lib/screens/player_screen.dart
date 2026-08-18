import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';
import '../services/audio_service.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../widgets/visualizer.dart';

class PlayerScreen extends StatefulWidget {
  final RadioStation station;

  const PlayerScreen({super.key, required this.station});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  final RadioAudioService _audioService = RadioAudioService();
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    // Initial check of playing state to start rotation if already playing
    if (_audioService.player.playing && _audioService.currentStation.value?.id == widget.station.id) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.station.primaryColor;
    final secondaryColor = widget.station.secondaryColor;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return StreamBuilder<PlayerState>(
      stream: _audioService.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;
        final processingState = playerState?.processingState ?? ProcessingState.idle;
        
        final isCurrentStation = _audioService.currentStation.value?.id == widget.station.id;
        final isStationPlaying = isCurrentStation && isPlaying;
        final isStationBuffering = isCurrentStation && 
            (processingState == ProcessingState.buffering || processingState == ProcessingState.loading);

        if (isStationPlaying) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
        } else {
          _rotationController.stop();
        }

        return Scaffold(
          body: Stack(
            children: [
              // Dynamic Background Gradient
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activeColor.withOpacity(0.25),
                      secondaryColor.withOpacity(0.1),
                      AppTheme.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Subtle colored fluid aura
              Positioned(
                top: -100,
                left: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withOpacity(0.15),
                    ),
                  ),
                ),
              ),

              // Main Interface Layout
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 16.0 : 24.0,
                    vertical: isLandscape ? 4.0 : 16.0,
                  ),
                  child: isLandscape
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left Column (Disc & Visualizer + Back button)
                            Expanded(
                              flex: 9,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Back Button Row
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                  // Vinyl Cover
                                  Center(
                                    child: _buildVinylCover(activeColor, isStationPlaying, isStationBuffering, 160),
                                  ),
                                  // Visualizer
                                  AudioVisualizer(
                                    isPlaying: isStationPlaying,
                                    color: activeColor,
                                    barCount: 15,
                                    height: 28,
                                    width: 120,
                                  ),
                                ],
                              ),
                            ),
                            // Divider
                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              color: Colors.white10,
                            ),
                            // Right Column (Details, Controls, volume)
                            Expanded(
                              flex: 11,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Category / Track Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "NOW PLAYING",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary.withOpacity(0.8),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      ValueListenableBuilder<List<String>>(
                                        valueListenable: _favoritesService.favorites,
                                        builder: (context, favoritesList, child) {
                                          final isFavorite = favoritesList.contains(widget.station.id);
                                          return IconButton(
                                            icon: Icon(
                                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              color: isFavorite ? const Color(0xFFFF2D55) : Colors.white,
                                              size: 24,
                                            ),
                                            onPressed: () => _favoritesService.toggleFavorite(widget.station.id),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Station Name
                                  Text(
                                    widget.station.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    widget.station.frequency,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: activeColor.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Stream Status & Metadata
                                  _buildMetadataStream(isCurrentStation, isStationPlaying, isStationBuffering, activeColor),
                                  const SizedBox(height: 6),
                                  // Control Buttons
                                  _buildControlButtons(isCurrentStation, isStationPlaying, isStationBuffering, activeColor, secondaryColor),
                                  const SizedBox(height: 6),
                                  // Volume Slider
                                  _buildVolumeSlider(activeColor),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            // Header Navigation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "NOW PLAYING",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary.withOpacity(0.8),
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.station.frequency,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                ValueListenableBuilder<List<String>>(
                                  valueListenable: _favoritesService.favorites,
                                  builder: (context, favoritesList, child) {
                                    final isFavorite = favoritesList.contains(widget.station.id);
                                    return IconButton(
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: isFavorite ? const Color(0xFFFF2D55) : Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () => _favoritesService.toggleFavorite(widget.station.id),
                                    );
                                  },
                                ),
                              ],
                            ),
                            
                            const Spacer(),

                            // Animated Pulsing vinyl cover
                            Center(
                              child: _buildVinylCover(activeColor, isStationPlaying, isStationBuffering, 230),
                            ),
                            
                            const Spacer(),

                            // Station Name & Description
                            Text(
                              widget.station.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Live stream Status & Metadata Viewer
                            _buildMetadataStream(isCurrentStation, isStationPlaying, isStationBuffering, activeColor),

                            // Audio Visualizer
                            const SizedBox(height: 16),
                            AudioVisualizer(
                              isPlaying: isStationPlaying,
                              color: activeColor,
                              barCount: 15,
                              height: 36,
                              width: 150,
                            ),
                            
                            const Spacer(),

                            // Audio control buttons
                            _buildControlButtons(isCurrentStation, isStationPlaying, isStationBuffering, activeColor, secondaryColor),
                            
                            const Spacer(),

                            // Volume Slider Card
                            _buildVolumeSlider(activeColor),
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVinylCover(Color activeColor, bool isStationPlaying, bool isStationBuffering, double size) {
    final ringSize = size + 20;
    final paddingSize = size * 0.17;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Neon glowing ring
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: activeColor.withOpacity(isStationPlaying ? 0.35 : 0.08),
                blurRadius: isStationPlaying ? 30 : 15,
                spreadRadius: isStationPlaying ? 8 : 1,
              ),
            ],
          ),
        ),
        
        // Vinyl physical disc look
        RotationTransition(
          turns: _rotationController,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.white12, width: 2),
              gradient: const RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black87,
                  Colors.black,
                ],
                stops: [0.0, 0.8, 1.0],
              ),
            ),
            padding: EdgeInsets.all(paddingSize),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [activeColor, widget.station.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipOval(
                child: _buildLogo(),
              ),
            ),
          ),
        ),

        // Buffering visual indicator
        if (isStationBuffering)
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
      ],
    );
  }

  Widget _buildMetadataStream(bool isCurrentStation, bool isStationPlaying, bool isStationBuffering, Color activeColor) {
    return Container(
      alignment: Alignment.center,
      height: 64,
      child: isCurrentStation
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // "LIVE STREAM" status indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isStationPlaying ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isStationPlaying ? "LIVE STREAM" : "BROADCAST STANDBY",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Dynamic playing tag
                Expanded(
                  child: StreamBuilder<String?>(
                    stream: _audioService.trackMetadataStream,
                    builder: (context, metadataSnapshot) {
                      final trackTitle = metadataSnapshot.data;
                      
                      if (isStationBuffering) {
                        return Text(
                          "Tuning in stream...",
                          style: TextStyle(
                            fontSize: 13,
                            color: activeColor.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          trackTitle ?? widget.station.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: trackTitle != null ? activeColor : AppTheme.textSecondary,
                            fontWeight: trackTitle != null ? FontWeight.w700 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : Text(
              "Not playing",
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
    );
  }

  Widget _buildControlButtons(bool isCurrentStation, bool isStationPlaying, bool isStationBuffering, Color activeColor, Color secondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop Broadcast Button
        IconButton(
          icon: const Icon(Icons.stop_circle_outlined, size: 36),
          color: isCurrentStation ? Colors.white70 : Colors.white24,
          onPressed: isCurrentStation ? () => _audioService.stop() : null,
        ),
        const SizedBox(width: 24),
        
        // Big Glowing Play/Pause Circle
        GestureDetector(
          onTap: () {
            if (isCurrentStation) {
              _audioService.togglePlay();
            } else {
              _audioService.playStation(widget.station);
            }
          },
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [activeColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: isStationBuffering
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isStationPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Status notification indicator
        IconButton(
          icon: Icon(
            isStationPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 30,
          ),
          color: Colors.white70,
          onPressed: () {
            if (isCurrentStation) {
              _audioService.setVolume(_audioService.player.volume > 0.1 ? 0.0 : 1.0);
            }
          },
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.glassDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: StreamBuilder<double>(
        stream: _audioService.volumeStream,
        builder: (context, volumeSnapshot) {
          final volume = volumeSnapshot.data ?? 1.0;
          return Row(
            children: [
              Icon(
                volume == 0.0
                    ? Icons.volume_mute_rounded
                    : volume < 0.5
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: activeColor,
                    thumbColor: activeColor,
                    overlayColor: activeColor.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) => _audioService.setVolume(val),
                  ),
                ),
              ),
              Text(
                "${(volume * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    final station = widget.station;
    final fallbackText = Center(
      child: Text(
        station.name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          fontSize: 68,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black38,
              offset: Offset(2, 4),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );

    return _buildNetworkLogo(fallbackText);
  }

  Widget _buildNetworkLogo(Widget fallback) {
    final station = widget.station;
    if (station.logoUrl == null) return fallback;

    return Image.network(
      station.logoUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
        );
      },
    );
  }
}
