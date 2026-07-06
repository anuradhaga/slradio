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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Neon glowing ring
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withOpacity(isStationPlaying ? 0.4 : 0.1),
                                    blurRadius: isStationPlaying ? 40 : 20,
                                    spreadRadius: isStationPlaying ? 10 : 2,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Vinyl physical disc look
                            RotationTransition(
                              turns: _rotationController,
                              child: Container(
                                width: 230,
                                height: 230,
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
                                padding: const EdgeInsets.all(40),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [activeColor, secondaryColor],
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
                              const SizedBox(
                                width: 245,
                                height: 245,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                          ],
                        ),
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
                      Container(
                        alignment: Alignment.center,
                        height: 72,
                        child: isCurrentStation
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // "LIVE STREAM" status indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isStationPlaying ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isStationPlaying ? "LIVE STREAM" : "BROADCAST STANDBY",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textSecondary.withOpacity(0.8),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  
                                  // Dynamic playing tag (track title or station description)
                                  Expanded(
                                    child: StreamBuilder<String?>(
                                      stream: _audioService.trackMetadataStream,
                                      builder: (context, metadataSnapshot) {
                                        final trackTitle = metadataSnapshot.data;
                                        
                                        if (isStationBuffering) {
                                          return Text(
                                            "Tuning in stream...",
                                            style: TextStyle(
                                              fontSize: 14,
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
                                              fontSize: 14,
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
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                      ),

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
                      Row(
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
                              width: 76,
                              height: 76,
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
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isStationBuffering
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(
                                        isStationPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 42,
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
                      ),
                      
                      const Spacer(),

                      // Volume Slider Card
                      Container(
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
                      ),
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

    if (station.logoAsset != null) {
      return Image.asset(
        station.logoAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildNetworkLogo(fallbackText);
        },
      );
    }

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
