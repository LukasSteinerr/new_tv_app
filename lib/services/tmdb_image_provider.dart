import 'dart:collection';
import 'dart:async';
import 'tmdb_service.dart';

/// A service that provides TMDB images with enhanced caching and performance optimization
class TMDBImageProvider {
  static final TMDBImageProvider _instance = TMDBImageProvider._internal();
  factory TMDBImageProvider() => _instance;

  TMDBImageProvider._internal();

  final TMDBService _tmdbService = TMDBService();

  // Enhanced cache with LRU eviction
  static const int _maxCacheSize = 500;
  final LinkedHashMap<String, String?> _posterCache = LinkedHashMap();
  final LinkedHashMap<String, String?> _backdropCache = LinkedHashMap();

  // Track ongoing requests to prevent duplicate API calls
  final Map<String, Completer<String?>> _ongoingRequests = {};

  String _createCacheKey(String type, String id, bool isBackdrop) {
    return "${type}_${isBackdrop ? 'backdrop' : 'poster'}_$id";
  }

  void _addToCache(
    LinkedHashMap<String, String?> cache,
    String key,
    String? value,
  ) {
    // Remove if already exists to update position
    cache.remove(key);

    // Add to end (most recently used)
    cache[key] = value;

    // Evict oldest if cache is too large
    while (cache.length > _maxCacheSize) {
      cache.remove(cache.keys.first);
    }
  }

  String? _getFromCache(LinkedHashMap<String, String?> cache, String key) {
    final value = cache.remove(key);
    if (value != null) {
      // Move to end (mark as recently used)
      cache[key] = value;
    }
    return value;
  }

  Future<String?> _getCachedOrFetch(
    String cacheKey,
    LinkedHashMap<String, String?> cache,
    Future<String?> Function() fetcher,
    String? fallbackUrl,
  ) async {
    // Check cache first
    final cachedValue = _getFromCache(cache, cacheKey);
    if (cachedValue != null) {
      return cachedValue;
    }

    // Check if request is already ongoing
    if (_ongoingRequests.containsKey(cacheKey)) {
      return await _ongoingRequests[cacheKey]!.future;
    }

    // Start new request
    final completer = Completer<String?>();
    _ongoingRequests[cacheKey] = completer;

    try {
      final result = await fetcher();
      final finalResult = result ?? fallbackUrl;

      // Cache the result
      _addToCache(cache, cacheKey, finalResult);

      completer.complete(finalResult);
      return finalResult;
    } catch (e) {
      completer.complete(fallbackUrl);
      return fallbackUrl;
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  /// Get a poster URL for a movie with enhanced caching
  Future<String?> getPosterUrl(String? tmdbId, String? fallbackUrl) async {
    if (tmdbId == null || tmdbId.isEmpty) {
      return fallbackUrl;
    }

    final cacheKey = _createCacheKey('movie', tmdbId, false);

    return await _getCachedOrFetch(cacheKey, _posterCache, () async {
      final images = await _tmdbService.getMovieImages(tmdbId);
      return images['poster'];
    }, fallbackUrl);
  }

  /// Get a backdrop URL for a movie with enhanced caching
  Future<String?> getBackdropUrl(String? tmdbId) async {
    if (tmdbId == null || tmdbId.isEmpty) {
      return null;
    }

    final cacheKey = _createCacheKey('movie', tmdbId, true);

    return await _getCachedOrFetch(cacheKey, _backdropCache, () async {
      final images = await _tmdbService.getMovieImages(tmdbId);
      return images['backdrop'];
    }, null);
  }

  /// Get a TV series poster URL with enhanced caching
  Future<String?> getTvPosterUrl(String? tmdbId, String? fallbackUrl) async {
    if (tmdbId == null || tmdbId.isEmpty) {
      return fallbackUrl;
    }

    final cacheKey = _createCacheKey('tv', tmdbId, false);

    return await _getCachedOrFetch(cacheKey, _posterCache, () async {
      final images = await _tmdbService.getTvSeriesImages(tmdbId);
      return images['poster'];
    }, fallbackUrl);
  }

  /// Get a TV series backdrop URL with enhanced caching
  Future<String?> getTvBackdropUrl(String? tmdbId) async {
    if (tmdbId == null || tmdbId.isEmpty) {
      return null;
    }

    final cacheKey = _createCacheKey('tv', tmdbId, true);

    return await _getCachedOrFetch(cacheKey, _backdropCache, () async {
      final images = await _tmdbService.getTvSeriesImages(tmdbId);
      return images['backdrop'];
    }, null);
  }

  /// Preload images for a list of IDs to improve performance
  Future<void> preloadImages(
    List<String> tmdbIds, {
    bool isMovie = true,
  }) async {
    final futures = tmdbIds
        .take(10)
        .map(
          (id) => isMovie ? getPosterUrl(id, null) : getTvPosterUrl(id, null),
        );

    await Future.wait(futures);
  }

  /// Get cache statistics for debugging
  Map<String, int> getCacheStats() {
    return {
      'posterCacheSize': _posterCache.length,
      'backdropCacheSize': _backdropCache.length,
      'ongoingRequests': _ongoingRequests.length,
    };
  }

  /// Clear all caches and ongoing requests
  void clearCache() {
    _posterCache.clear();
    _backdropCache.clear();

    // Cancel ongoing requests
    for (final completer in _ongoingRequests.values) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _ongoingRequests.clear();
  }

  /// Clear old cache entries (keep only recent ones)
  void clearOldCache({int keepRecentCount = 100}) {
    while (_posterCache.length > keepRecentCount) {
      _posterCache.remove(_posterCache.keys.first);
    }
    while (_backdropCache.length > keepRecentCount) {
      _backdropCache.remove(_backdropCache.keys.first);
    }
  }
}
