import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';
import '../services/audio_service.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../widgets/station_card.dart';
import '../widgets/mini_player.dart';
import '../widgets/visualizer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RadioAudioService _audioService = RadioAudioService();
  final FavoritesService _favoritesService = FavoritesService();
  
  String _searchQuery = '';
  String _selectedCategory = 'All'; // 'All' or 'Favorites'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _favoritesService.initialize().then((_) {
      if (_favoritesService.favorites.value.isNotEmpty) {
        setState(() {
          _selectedCategory = 'Favorites';
        });
      }
    });
    _audioService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(
        children: [
          // Background soft gradient
          Positioned(
            top: -200,
            right: -200,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withOpacity(0.08),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Column (Stations list)
                      Expanded(
                        flex: 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(isLandscape),
                            _buildSearchInput(isLandscape),
                            _buildCategories(isLandscape),
                            Expanded(child: _buildStationsList(isLandscape)),
                          ],
                        ),
                      ),
                      // Vertical Divider
                      Container(
                        width: 1,
                        color: Colors.white10,
                      ),
                      // Right Column (Now Playing Panel)
                      Expanded(
                        flex: 9,
                        child: _buildRightPanel(),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isLandscape),
                      _buildSearchInput(isLandscape),
                      _buildCategories(isLandscape),
                      Expanded(child: _buildStationsList(isLandscape)),
                    ],
                  ),
          ),

          // Floating mini audio player (only for portrait)
          if (!isLandscape)
            const Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayer(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isLandscape ? 16.0 : 24.0,
        isLandscape ? 8.0 : 16.0,
        isLandscape ? 16.0 : 24.0,
        isLandscape ? 4.0 : 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: isLandscape ? 11 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Sri Lanka Radio",
                style: TextStyle(
                  fontSize: isLandscape ? 20 : 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            width: isLandscape ? 36 : 44,
            height: isLandscape ? 36 : 44,
            decoration: AppTheme.glassDecoration(
              borderRadius: BorderRadius.circular(isLandscape ? 10 : 14),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.radio_rounded,
              color: AppTheme.accentGlow,
              size: isLandscape ? 20 : 24,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchInput(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 16.0 : 24.0,
        vertical: isLandscape ? 6.0 : 12.0,
      ),
      child: Container(
        decoration: AppTheme.glassDecoration(
          borderRadius: BorderRadius.circular(isLandscape ? 14 : 18),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim().toLowerCase();
            });
          },
          style: TextStyle(color: Colors.white, fontSize: isLandscape ? 14 : 15),
          decoration: InputDecoration(
            hintText: "Search stations, frequencies...",
            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: isLandscape ? 14 : 15),
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: isLandscape ? 20 : 24),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: isLandscape ? 18 : 22),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: isLandscape ? 10 : 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 16.0 : 24.0,
        vertical: isLandscape ? 4.0 : 8.0,
      ),
      child: Row(
        children: [
          _buildCategoryPill('All'),
          const SizedBox(width: 12),
          _buildCategoryPill('Favorites'),
        ],
      ),
    );
  }

  Widget _buildStationsList(bool isLandscape) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _favoritesService.favorites,
      builder: (context, favoritesList, child) {
        // Filter stations list based on search query and category
        final List<RadioStation> displayedStations = RadioStation.stations.where((station) {
          final matchesSearch = station.name.toLowerCase().contains(_searchQuery) ||
              station.frequency.toLowerCase().contains(_searchQuery) ||
              station.description.toLowerCase().contains(_searchQuery);
              
          if (_selectedCategory == 'Favorites') {
            return matchesSearch && favoritesList.contains(station.id);
          }
          return matchesSearch;
        }).toList();

        // Sort stations ascending by name (alphabetically)
        displayedStations.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return CustomScrollView(
          slivers: [
            // Header for grid section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isLandscape ? 16.0 : 24.0,
                  isLandscape ? 8.0 : 16.0,
                  isLandscape ? 16.0 : 24.0,
                  isLandscape ? 6.0 : 12.0,
                ),
                child: Text(
                  _selectedCategory == 'Favorites' 
                      ? "MY FAVORITES (${displayedStations.length})" 
                      : "ALL ONLINE STATIONS (${displayedStations.length})",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            // Stations lists grid
            if (displayedStations.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedCategory == 'Favorites'
                            ? Icons.favorite_border_rounded
                            : Icons.radio_rounded,
                        size: isLandscape ? 48 : 64,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedCategory == 'Favorites'
                            ? "No favorites added yet"
                            : "No matching stations found",
                        style: TextStyle(
                          fontSize: isLandscape ? 14 : 16,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCategory == 'Favorites'
                            ? "Tap the heart on any station card to save here"
                            : "Try searching with a different name or frequency",
                        style: TextStyle(
                          fontSize: isLandscape ? 11 : 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isLandscape ? 16.0 : 24.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final station = displayedStations[index];
                      
                      return ValueListenableBuilder<RadioStation?>(
                        valueListenable: _audioService.currentStation,
                        builder: (context, activeStation, child) {
                          return StreamBuilder<PlayerState>(
                            stream: _audioService.playerStateStream,
                            builder: (context, snapshot) {
                              final playerState = snapshot.data;
                              final isPlaying = playerState?.playing ?? false;
                              final processingState = playerState?.processingState ?? ProcessingState.idle;
                              
                              final isActive = activeStation?.id == station.id;
                              final isStationPlaying = isActive && isPlaying;
                              final isStationBuffering = isActive && 
                                  (processingState == ProcessingState.buffering || 
                                   processingState == ProcessingState.loading);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: StationCard(
                                  station: station,
                                  isActive: isActive,
                                  isPlaying: isStationPlaying,
                                  isBuffering: isStationBuffering,
                                  isFavorite: favoritesList.contains(station.id),
                                  onTap: () {
                                    if (isActive) {
                                      _audioService.togglePlay();
                                    } else {
                                      _audioService.playStation(station);
                                    }
                                  },
                                  onFavoriteToggle: () => _favoritesService.toggleFavorite(station.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    childCount: displayedStations.length,
                  ),
                ),
              ),
            
            // Bottom offset padding space so elements are not hidden by the floating player
            SliverToBoxAdapter(
              child: SizedBox(height: isLandscape ? 24 : 100),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRightPanel() {
    return ValueListenableBuilder<RadioStation?>(
      valueListenable: _audioService.currentStation,
      builder: (context, station, child) {
        if (station == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.radio_rounded,
                  size: 64,
                  color: AppTheme.textMuted.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No Station Playing",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Select a station from the list\nto start listening.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        final activeColor = station.primaryColor;
        final secondaryColor = station.secondaryColor;

        return StreamBuilder<PlayerState>(
          stream: _audioService.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final isPlaying = playerState?.playing ?? false;
            final processingState = playerState?.processingState ?? ProcessingState.idle;
            
            final isStationPlaying = isPlaying;
            final isStationBuffering = 
                processingState == ProcessingState.buffering || 
                processingState == ProcessingState.loading;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    activeColor.withOpacity(0.12),
                    secondaryColor.withOpacity(0.04),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Station logo / Avatar
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withOpacity(isStationPlaying ? 0.35 : 0.05),
                                    blurRadius: isStationPlaying ? 24 : 12,
                                    spreadRadius: isStationPlaying ? 4 : 1,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                border: Border.all(color: Colors.white12, width: 1.5),
                              ),
                              child: ClipOval(
                                child: _buildRightPanelLogo(station),
                              ),
                            ),
                            if (isStationBuffering)
                              SizedBox(
                                width: 76,
                                height: 76,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Station name & frequency
                      Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        station.frequency,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: activeColor.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Live Metadata
                      Container(
                        height: 38,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isStationPlaying)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "LIVE",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary.withOpacity(0.7),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 2),
                            Expanded(
                              child: StreamBuilder<String?>(
                                stream: _audioService.trackMetadataStream,
                                builder: (context, metadataSnapshot) {
                                  final trackTitle = metadataSnapshot.data;
                                  if (isStationBuffering) {
                                    return Text(
                                      "Tuning stream...",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: activeColor.withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }
                                  return Text(
                                    trackTitle ?? station.description,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: trackTitle != null ? activeColor : AppTheme.textSecondary,
                                      fontWeight: trackTitle != null ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Audio Visualizer
                      const SizedBox(height: 2),
                      AudioVisualizer(
                        isPlaying: isStationPlaying,
                        color: activeColor,
                        barCount: 9,
                        height: 16,
                        width: 90,
                      ),

                      const SizedBox(height: 6),

                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Favorite button
                          ValueListenableBuilder<List<String>>(
                            valueListenable: _favoritesService.favorites,
                            builder: (context, favoritesList, child) {
                              final isFavorite = favoritesList.contains(station.id);
                              return IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFavorite ? const Color(0xFFFF2D55) : Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => _favoritesService.toggleFavorite(station.id),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          // Play/Pause button
                          GestureDetector(
                            onTap: () => _audioService.togglePlay(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [activeColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isStationBuffering
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(
                                        isStationPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Stop button
                          IconButton(
                            icon: const Icon(Icons.stop_rounded, size: 20),
                            color: Colors.white70,
                            onPressed: () => _audioService.stop(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Volume slider
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: AppTheme.glassDecoration(
                          borderRadius: BorderRadius.circular(8),
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
                                  size: 12,
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: activeColor,
                                      thumbColor: activeColor,
                                      overlayColor: activeColor.withOpacity(0.1),
                                      trackHeight: 1.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
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
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRightPanelLogo(RadioStation station) {
    final fallbackText = Center(
      child: Text(
        station.name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          fontSize: 28,
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
          return _buildRightPanelNetworkLogo(station, fallbackText);
        },
      );
    }
    return _buildRightPanelNetworkLogo(station, fallbackText);
  }

  Widget _buildRightPanelNetworkLogo(RadioStation station, Widget fallback) {
    if (station.logoUrl == null) return fallback;
    return Image.network(
      station.logoUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Widget _buildCategoryPill(String category) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.accentGlow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
