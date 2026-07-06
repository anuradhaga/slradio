import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;

  final ValueNotifier<List<String>> _favorites = ValueNotifier<List<String>>([]);
  static const String _prefsKey = 'favorite_radio_stations';
  bool _isInitialized = false;

  FavoritesService._internal();

  ValueListenable<List<String>> get favorites => _favorites;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await loadFavorites();
    _isInitialized = true;
  }

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey) ?? [];
      _favorites.value = list;
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  bool isFavorite(String stationId) {
    return _favorites.value.contains(stationId);
  }

  Future<void> toggleFavorite(String stationId) async {
    await initialize();
    
    final currentList = List<String>.from(_favorites.value);
    if (currentList.contains(stationId)) {
      currentList.remove(stationId);
    } else {
      currentList.add(stationId);
    }

    _favorites.value = currentList;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, currentList);
    } catch (e) {
      debugPrint("Error saving favorites: $e");
    }
  }
}
