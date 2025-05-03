import 'package:flutter/material.dart';
import 'dart:collection';
import 'tmdb_service.dart';

/// A service that provides TMDB images with caching
class TMDBImageProvider {
  static final TMDBImageProvider _instance = TMDBImageProvider._internal();
  factory TMDBImageProvider() => _instance;
  
  TMDBImageProvider._internal();
  
  final TMDBService _tmdbService = TMDBService();
  
  // Cache for poster URLs
  final Map<String, String?> _posterCache = HashMap<String, String?>();
  
  // Cache for backdrop URLs
  final Map<String, String?> _backdropCache = HashMap<String, String?>();
  
  /// Get a poster URL for a movie or TV show
  /// Returns the fallback URL if TMDB ID is null or empty
  /// or if the image is not yet loaded
  Future<String?> getPosterUrl(String? tmdbId, String? fallbackUrl) async {
    // If no TMDB ID, return fallback
    if (tmdbId == null || tmdbId.isEmpty) {
      return fallbackUrl;
    }
    
    // Check cache first
    if (_posterCache.containsKey(tmdbId)) {
      return _posterCache[tmdbId] ?? fallbackUrl;
    }
    
    // Not in cache, load it
    try {
      final images = await _tmdbService.getMovieImages(tmdbId);
      final posterUrl = images['poster'];
      
      // Cache the result (even if null)
      _posterCache[tmdbId] = posterUrl;
      
      return posterUrl ?? fallbackUrl;
    } catch (e) {
      // On error, return fallback
      return fallbackUrl;
    }
  }
  
  /// Get a backdrop URL for a movie or TV show
  Future<String?> getBackdropUrl(String? tmdbId) async {
    // If no TMDB ID, return null
    if (tmdbId == null || tmdbId.isEmpty) {
      return null;
    }
    
    // Check cache first
    if (_backdropCache.containsKey(tmdbId)) {
      return _backdropCache[tmdbId];
    }
    
    // Not in cache, load it
    try {
      final images = await _tmdbService.getMovieImages(tmdbId);
      final backdropUrl = images['backdrop'];
      
      // Cache the result (even if null)
      _backdropCache[tmdbId] = backdropUrl;
      
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
    
    // Check cache first
    if (_posterCache.containsKey('tv_$tmdbId')) {
      return _posterCache['tv_$tmdbId'] ?? fallbackUrl;
    }
    
    // Not in cache, load it
    try {
      final images = await _tmdbService.getTvSeriesImages(tmdbId);
      final posterUrl = images['poster'];
      
      // Cache the result (even if null)
      _posterCache['tv_$tmdbId'] = posterUrl;
      
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
    
    // Check cache first
    if (_backdropCache.containsKey('tv_$tmdbId')) {
      return _backdropCache['tv_$tmdbId'];
    }
    
    // Not in cache, load it
    try {
      final images = await _tmdbService.getTvSeriesImages(tmdbId);
      final backdropUrl = images['backdrop'];
      
      // Cache the result (even if null)
      _backdropCache['tv_$tmdbId'] = backdropUrl;
      
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
