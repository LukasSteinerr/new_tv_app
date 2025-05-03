import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDBService {
  // TMDB API base URLs
  static const String _apiBaseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p';

  // TODO: Replace with your TMDB API key from https://www.themoviedb.org/settings/api
  // You need to create an account and request an API key
  static const String _apiKey = '9e92699e050cb40728b59728c3115455';

  // Image sizes
  static const String _posterSize = 'w500';
  static const String _backdropSize = 'w1280';

  // Get full image URLs
  static String getPosterUrl(String path) => '$_imageBaseUrl/$_posterSize$path';
  static String getBackdropUrl(String path) =>
      '$_imageBaseUrl/$_backdropSize$path';

  // Fetch movie details by TMDB ID
  Future<Map<String, dynamic>?> getMovieDetails(String tmdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/movie/$tmdbId?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching movie details: $e');
      return null;
    }
  }

  // Fetch TV series details by TMDB ID
  Future<Map<String, dynamic>?> getTvSeriesDetails(String tmdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/tv/$tmdbId?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching TV series details: $e');
      return null;
    }
  }

  // Get movie poster and backdrop URLs
  Future<Map<String, String?>> getMovieImages(String tmdbId) async {
    final details = await getMovieDetails(tmdbId);
    if (details == null) {
      return {'poster': null, 'backdrop': null};
    }

    String? posterPath = details['poster_path'];
    String? backdropPath = details['backdrop_path'];

    return {
      'poster': posterPath != null ? getPosterUrl(posterPath) : null,
      'backdrop': backdropPath != null ? getBackdropUrl(backdropPath) : null,
    };
  }

  // Get TV series poster and backdrop URLs
  Future<Map<String, String?>> getTvSeriesImages(String tmdbId) async {
    final details = await getTvSeriesDetails(tmdbId);
    if (details == null) {
      return {'poster': null, 'backdrop': null};
    }

    String? posterPath = details['poster_path'];
    String? backdropPath = details['backdrop_path'];

    return {
      'poster': posterPath != null ? getPosterUrl(posterPath) : null,
      'backdrop': backdropPath != null ? getBackdropUrl(backdropPath) : null,
    };
  }
}
