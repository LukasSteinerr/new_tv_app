import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cast.dart';
import '../models/movie.dart'; // Import the Movie model
import '../models/tv_series.dart'; // Import the TvSeries model

class TMDBService {
  // TMDB API base URLs
  static const String _apiBaseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p';

  // TODO: Replace with your TMDB API key from https://www.themoviedb.org/settings/api
  // You need to create an account and request an API key
  static const String _apiKey = '9e92699e050cb40728b59728c3115455';

  // Image sizes
  static const String _posterSize =
      'w500'; // Default resolution for content carousel posters
  static const String _featuredPosterSize =
      'w780'; // Higher resolution for featured content posters
  static const String _backdropSize = 'w1280';

  // Get full image URLs
  static String getPosterUrl(String path) => '$_imageBaseUrl/$_posterSize$path';
  static String getFeaturedPosterUrl(String path) =>
      '$_imageBaseUrl/$_featuredPosterSize$path';
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

  // Fetch movie credits by TMDB ID
  Future<List<Cast>> getMovieCredits(String tmdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/movie/$tmdbId/credits?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> castData = data['cast'];
        return castData.map((json) => Cast.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching movie credits: $e');
      return [];
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

  // Fetch popular movies
  Future<List<Movie>> getPopularMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/movie/popular?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        return results.map((movieData) {
          // Ensure streamUrl is provided, even if it's a placeholder or empty,
          // as it's required by the Movie constructor.
          // For TMDB movies not directly in a playlist, streamUrl might not be applicable
          // or could be set later if the movie is matched with a playlist item.
          // For now, providing a default or empty string.
          String streamUrl = ''; // Placeholder or default

          // Try to get a streamId if available, otherwise null
          // This field is more relevant for playlist items.
          String? streamId =
              movieData['id']
                  ?.toString(); // Using TMDB movie id as a potential streamId for now

          return Movie(
            // Assuming 'name' in Movie model maps to 'title' from TMDB
            name: movieData['title'] ?? 'No Title',
            // streamUrl is required, provide a sensible default or handle appropriately
            streamUrl: streamUrl,
            description: movieData['overview'] ?? '',
            // Movie model's 'year' vs TMDB's 'release_date' (String YYYY-MM-DD)
            // Extract year from release_date
            year:
                movieData['release_date'] != null &&
                        movieData['release_date'].length >= 4
                    ? movieData['release_date'].substring(0, 4)
                    : null,
            // Movie model's 'rating' vs TMDB's 'vote_average' (double)
            rating: movieData['vote_average']?.toString() ?? '0.0',
            tmdbId: movieData['id']?.toString(),
            posterUrl:
                movieData['poster_path'] != null
                    ? getPosterUrl(movieData['poster_path'])
                    : null,
            backdropUrl:
                movieData['backdrop_path'] != null
                    ? getBackdropUrl(movieData['backdrop_path'])
                    : null,
            featuredPosterUrl:
                movieData['poster_path'] != null
                    ? getFeaturedPosterUrl(movieData['poster_path'])
                    : null,
            // Other fields like duration, trailer, added, rating_5based might need
            // more detailed fetching or might not be directly available from popular list
            streamId: streamId, // Assigning TMDB id as streamId for now
            isFeatured: true, // Mark as featured
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching popular movies: $e');
      return [];
    }
  }

  // Fetch popular TV series
  Future<List<TvSeries>> getPopularTvSeries() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/tv/popular?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        return results.map((tvSeriesData) {
          return TvSeries(
            name: tvSeriesData['name'] ?? 'No Title',
            description: tvSeriesData['overview'] ?? '',
            year:
                tvSeriesData['first_air_date'] != null &&
                        tvSeriesData['first_air_date'].length >= 4
                    ? tvSeriesData['first_air_date'].substring(0, 4)
                    : null,
            rating: tvSeriesData['vote_average']?.toString() ?? '0.0',
            tmdbId: tvSeriesData['id']?.toString(),
            coverUrl:
                tvSeriesData['poster_path'] != null
                    ? getPosterUrl(tvSeriesData['poster_path'])
                    : null,
            featuredPosterUrl:
                tvSeriesData['poster_path'] != null
                    ? getFeaturedPosterUrl(tvSeriesData['poster_path'])
                    : null,
            isFeatured: true, // Mark as featured
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching popular TV series: $e');
      return [];
    }
  }

  // Fetch similar movies by TMDB ID
  Future<List<Movie>> getSimilarMovies(String tmdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/movie/$tmdbId/similar?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        return results.map((movieData) {
          String streamUrl = ''; // Placeholder
          String? streamId = movieData['id']?.toString();

          return Movie(
            name: movieData['title'] ?? 'No Title',
            streamUrl: streamUrl,
            description: movieData['overview'] ?? '',
            year:
                movieData['release_date'] != null &&
                        movieData['release_date'].length >= 4
                    ? movieData['release_date'].substring(0, 4)
                    : null,
            rating: movieData['vote_average']?.toString() ?? '0.0',
            tmdbId: movieData['id']?.toString(),
            posterUrl:
                movieData['poster_path'] != null
                    ? getPosterUrl(movieData['poster_path'])
                    : null,
            backdropUrl:
                movieData['backdrop_path'] != null
                    ? getBackdropUrl(movieData['backdrop_path'])
                    : null,
            featuredPosterUrl:
                movieData['poster_path'] != null
                    ? getFeaturedPosterUrl(movieData['poster_path'])
                    : null,
            streamId: streamId,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching similar movies: $e');
      return [];
    }
  }
}
