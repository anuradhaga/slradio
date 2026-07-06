import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../screens/player_screen.dart';
import 'visualizer.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = RadioAudioService();

    return ValueListenableBuilder<RadioStation?>(
      valueListenable: audioService.currentStation,
      builder: (context, station, child) {
        if (station == null) return const SizedBox.shrink();

        return StreamBuilder<PlayerState>(
          stream: audioService.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final isPlaying = playerState?.playing ?? false;
            final processingState = playerState?.processingState ?? ProcessingState.idle;
            
            final isBuffering = processingState == ProcessingState.buffering ||
                processingState == ProcessingState.loading;

            final activeColor = station.primaryColor;

            return Dismissible(
              key: Key(station.id),
              direction: DismissDirection.down,
              onDismissed: (_) => audioService.stop(),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          PlayerScreen(station: station),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutCubic;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        color: Colors.black.withOpacity(0.45),
                        child: Row(
                          children: [
                            // Station avatar/logo
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        station.primaryColor,
                                        station.secondaryColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _buildLogo(station),
                                  ),
                                ),
                                if (isBuffering)
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            
                            // Station Title & Info
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  
                                  // Live metadata track details or fallback description
                                  StreamBuilder<String?>(
                                    stream: audioService.trackMetadataStream,
                                    builder: (context, metadataSnapshot) {
                                      final trackTitle = metadataSnapshot.data;
                                      return Text(
                                        trackTitle ?? '${station.frequency} • Live Stream',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: trackTitle != null 
                                              ? activeColor.withOpacity(0.9) 
                                              : AppTheme.textSecondary,
                                          fontWeight: trackTitle != null 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            // Visualizer when active
                            if (isPlaying && !isBuffering)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: AudioVisualizer(
                                  isPlaying: true,
                                  color: activeColor,
                                  barCount: 4,
                                  height: 16,
                                  width: 18,
                                ),
                              ),
                            
                            // Play/Pause Action Button
                            IconButton(
                              icon: isBuffering
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_filled_rounded,
                                      color: Colors.white,
                                      size: 38,
                                    ),
                              onPressed: () => audioService.togglePlay(),
                            ),
                            
                            // Close Action Button
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white60,
                                size: 20,
                              ),
                              onPressed: () => audioService.stop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogo(RadioStation station) {
    final fallbackText = Center(
      child: Text(
        station.name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    if (station.logoAsset != null) {
      return Image.asset(
        station.logoAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildNetworkLogo(station, fallbackText);
        },
      );
    }

    return _buildNetworkLogo(station, fallbackText);
  }

  Widget _buildNetworkLogo(RadioStation station, Widget fallback) {
    if (station.logoUrl == null) return fallback;

    return Image.network(
      station.logoUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
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
