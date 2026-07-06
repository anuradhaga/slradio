import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';
import '../services/audio_service.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../widgets/station_card.dart';
import '../widgets/mini_player.dart';

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
    _favoritesService.initialize();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (Greeting & Title)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Sri Lanka Radio",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: AppTheme.glassDecoration(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.radio_rounded,
                          color: AppTheme.accentGlow,
                          size: 24,
                        ),
                      )
                    ],
                  ),
                ),

                // Interactive Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Container(
                    decoration: AppTheme.glassDecoration(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Search stations, frequencies...",
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // Category selection pills
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _buildCategoryPill('All'),
                      const SizedBox(width: 12),
                      _buildCategoryPill('Favorites'),
                    ],
                  ),
                ),

                // Main stations feed list
                Expanded(
                  child: ValueListenableBuilder<List<String>>(
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
                              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 12.0),
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
                                      size: 64,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _selectedCategory == 'Favorites'
                                          ? "No favorites added yet"
                                          : "No matching stations found",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _selectedCategory == 'Favorites'
                                          ? "Tap the heart on any station card to save here"
                                          : "Try searching with a different name or frequency",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Floating mini audio player
          const Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(),
          ),
        ],
      ),
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
