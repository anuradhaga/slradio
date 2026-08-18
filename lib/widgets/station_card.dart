import 'package:flutter/material.dart';
import '../models/station.dart';
import '../theme/app_theme.dart';
import 'visualizer.dart';

class StationCard extends StatefulWidget {
  final RadioStation station;
  final bool isActive;
  final bool isPlaying;
  final bool isBuffering;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const StationCard({
    super.key,
    required this.station,
    required this.isActive,
    required this.isPlaying,
    required this.isBuffering,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  State<StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.station.primaryColor;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16.0),
            decoration: AppTheme.glassDecoration(
              customColor: widget.isActive 
                  ? activeColor.withOpacity(0.12)
                  : _isHovered ? Colors.white.withOpacity(0.09) : null,
              customBorderColor: widget.isActive
                  ? activeColor.withOpacity(0.4)
                  : _isHovered ? Colors.white.withOpacity(0.15) : null,
            ),
            child: Row(
              children: [
                // Station Stylized Avatar / Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Active glowing aura
                    if (widget.isActive && widget.isPlaying)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    
                    // Main Avatar Container
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.station.primaryColor,
                            widget.station.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipOval(
                        child: _buildLogo(),
                      ),
                    ),
                    
                    // Loading overlay when buffering
                    if (widget.isActive && widget.isBuffering)
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Station Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.station.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: widget.isActive ? Colors.white : AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.station.frequency,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.isActive 
                              ? activeColor.withOpacity(0.9)
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.station.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Active visualizer or Play Icon / Favorite
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isActive && widget.isPlaying)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: AudioVisualizer(
                          isPlaying: true,
                          color: activeColor,
                          barCount: 5,
                          height: 20,
                          width: 25,
                        ),
                      )
                    else if (widget.isActive && widget.isBuffering)
                      const SizedBox(width: 37)
                    else if (widget.isActive)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: activeColor,
                          size: 24,
                        ),
                      ),
                    
                    // Favorite button
                    IconButton(
                      icon: Icon(
                        widget.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: widget.isFavorite
                            ? const Color(0xFFFF2D55)
                            : AppTheme.textSecondary.withOpacity(0.6),
                      ),
                      onPressed: widget.onFavoriteToggle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final station = widget.station;
    final fallbackText = Center(
      child: Text(
        station.name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
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
            width: 20,
            height: 20,
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
