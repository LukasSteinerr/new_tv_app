import 'dart:collection';
import 'tmdb_service.dart';

/// A service that provides TMDB images with caching
class TMDBImageProvider {
  static final TMDBImageProvider _instance = TMDBImageProvider._internal();
  factory TMDBImageProvider() => _instance;

  TMDBImageProvider._internal();

  final TMDBService _tmdbService = TMDBService();

  // Cache for poster URLs - use distinct keys for movies and TV shows
  final Map<String, String?> _posterCache = HashMap<String, String?>();

  // Cache for backdrop URLs - use distinct keys for movies and TV shows
  final Map<String, String?> _backdropCache = HashMap<String, String?>();

  // Helper method to create distinct cache keys
  String _createCacheKey(String type, String id, bool isBackdrop) {
    return "${type}_${isBackdrop ? 'backdrop' : 'poster'}_$id";
  }

  /// Get a poster URL for a movie
  /// Returns the fallback URL if TMDB ID is null or empty
  /// or if the image is not yet loaded
  Future<String?> getPosterUrl(String? tmdbId, String? fallbackUrl) async {
    // If no TMDB ID, return fallback
    if (tmdbId == null || tmdbId.isEmpty) {
      return fallbackUrl;
    }

    // Create a distinct cache key for movie posters
    final cacheKey = _createCacheKey('movie', tmdbId, false);

    // Check cache first
    if (_posterCache.containsKey(cacheKey)) {
      return _posterCache[cacheKey] ?? fallbackUrl;
    }

    // Not in cache, load it
    try {
      final images = await _tmdbService.getMovieImages(tmdbId);
      final posterUrl = images['poster'];

      // Cache the result (even if null)
      _posterCache[cacheKey] = posterUrl;

      return posterUrl ?? fallbackUrl;
    } catch (e) {
      // On error, return fallback
      return fallbackUrl;
    }
  }

  /// Get a backdrop URL for a movie
  Future<String?> getBackdropUrl(String? tmdbId) async {
    // If no TMDB ID, return null
    if (tmdbId == null || tmdbId.isEmpty) {
      return null;
    }

    // Create a distinct cache key for movie backdrops
    final cacheKey = _createCacheKey('movie', tmdbId, true);

    // Check cache first
    if (_backdropCache.containsKey(cacheKey)) {
      return _backdropCache[cacheKey];
    }

    // Not in cache, load it
    try {
      final images = await _tmdbService.getMovieImages(tmdbId);
      final backdropUrl = images['backdrop'];

      // Cache the result (even if null)
      _backdropCache[cacheKey] = backdropUrl;

      return backdropUrl;
    } catch (e) {
      return null;
    }
  }

  /// Get a TV series poster URL
  Future<String?> getTvPosterUrl(String? tmdbId, String? fallbackUrl) async {
    // If no TMDB ID, return fallback
    if (tmdbId == null || tmdbId.isEmpty) {
      return fallbackUrl;
    }

    // Create a distinct cache key for TV posters
    final cacheKey = _createCacheKey('tv', tmdbId, false);

    // Check cache first
    if (_posterCache.containsKey(cacheKey)) {
      return _posterCache[cacheKey] ?? fallbackUrl;
    }

    // Not in cache, load it
    try {
      final images = await _tmdbService.getTvSeriesImages(tmdbId);
      final posterUrl = images['poster'];

      // Cache the result (even if null)
      _posterCache[cacheKey] = posterUrl;

      return posterUrl ?? fallbackUrl;
    } catch (e) {
      // On error, return fallback
      return fallbackUrl;
    }
  }

  /// Get a TV series backdrop URL
  Future<String?> getTvBackdropUrl(String? tmdbId) async {
    // If no TMDB ID, return null
    if (tmdbId == null || tmdbId.isEmpty) {
      return null;
    }

    // Create a distinct cache key for TV backdrops
    final cacheKey = _createCacheKey('tv', tmdbId, true);

    // Check cache first
    if (_backdropCache.containsKey(cacheKey)) {
      return _backdropCache[cacheKey];
    }

    // Not in cache, load it
    try {
      final images = await _tmdbService.getTvSeriesImages(tmdbId);
      final backdropUrl = images['backdrop'];

      // Cache the result (even if null)
      _backdropCache[cacheKey] = backdropUrl;

      return backdropUrl;
    } catch (e) {
      return null;
    }
  }

  /// Clear all caches
  void clearCache() {
    _posterCache.clear();
    _backdropCache.clear();
  }
}
