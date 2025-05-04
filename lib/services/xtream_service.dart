import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../models/tv_episode.dart';

class XtreamService {
  Future<Map<String, dynamic>> fetchXtreamData(Playlist playlist) async {
    if (playlist.username == null || playlist.password == null) {
      throw Exception(
        'Username and password are required for Xtream playlists',
      );
    }

    try {
      // Parse the base URL from the provided URL
      final uri = Uri.parse(playlist.url);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';

      // Fetch live TV categories and channels
      final liveData = await _fetchLiveData(baseUrl, playlist);

      // Fetch movie categories and movies
      final movieData = await _fetchMovieData(baseUrl, playlist);

      // Fetch series categories and series
      final seriesData = await _fetchSeriesData(baseUrl, playlist);

      return {
        'channels': liveData['channels'],
        'categories': liveData['categories'],
        'movies': movieData['movies'],
        'movieCategories': movieData['categories'],
        'series': seriesData['series'],
        'seriesCategories': seriesData['categories'],
      };
    } catch (e) {
      throw Exception('Error fetching Xtream data: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchLiveData(
    String baseUrl,
    Playlist playlist,
  ) async {
    // Fetch live categories
    final categoriesResponse = await http.get(
      Uri.parse(
        '$baseUrl/player_api.php?username=${playlist.username}&password=${playlist.password}&action=get_live_categories',
      ),
    );

    if (categoriesResponse.statusCode != 200) {
      throw Exception(
        'Failed to load live categories: ${categoriesResponse.statusCode}',
      );
    }

    final categoriesJson = json.decode(categoriesResponse.body);
    final categories = <Category>[];
    final categoryMap = <String, Category>{};

    for (final categoryData in categoriesJson) {
      final category = Category(
        name: categoryData['category_name'],
        contentType: ContentType.liveTV,
      );
      category.playlist.target = playlist;
      categories.add(category);
      categoryMap[categoryData['category_id'].toString()] = category;
    }

    // Fetch channels
    final channelsResponse = await http.get(
      Uri.parse(
        '$baseUrl/player_api.php?username=${playlist.username}&password=${playlist.password}&action=get_live_streams',
      ),
    );

    if (channelsResponse.statusCode != 200) {
      throw Exception(
        'Failed to load channels: ${channelsResponse.statusCode}',
      );
    }

    final channelsJson = json.decode(channelsResponse.body);
    final channels = <Channel>[];

    for (final channelData in channelsJson) {
      final streamUrl =
          '$baseUrl/live/${playlist.username}/${playlist.password}/${channelData['stream_id']}.ts';

      final channel = Channel(
        name: channelData['name'],
        streamUrl: streamUrl,
        logoUrl: channelData['stream_icon'],
        epgId: channelData['epg_channel_id'],
      );

      channel.playlist.target = playlist;

      final categoryId = channelData['category_id'].toString();
      if (categoryMap.containsKey(categoryId)) {
        channel.category.target = categoryMap[categoryId];
      }

      channels.add(channel);
    }

    return {'channels': channels, 'categories': categories};
  }

  Future<Map<String, dynamic>> _fetchMovieData(
    String baseUrl,
    Playlist playlist,
  ) async {
    // Fetch movie categories
    final categoriesResponse = await http.get(
      Uri.parse(
        '$baseUrl/player_api.php?username=${playlist.username}&password=${playlist.password}&action=get_vod_categories',
      ),
    );

    if (categoriesResponse.statusCode != 200) {
      throw Exception(
        'Failed to load movie categories: ${categoriesResponse.statusCode}',
      );
    }

    final categoriesJson = json.decode(categoriesResponse.body);
    final categories = <Category>[];
    final categoryMap = <String, Category>{};

    for (final categoryData in categoriesJson) {
      final category = Category(
        name: categoryData['category_name'],
        contentType: ContentType.movie,
      );
      category.playlist.target = playlist;
      categories.add(category);
      categoryMap[categoryData['category_id'].toString()] = category;
    }

    // Fetch movies
    final moviesResponse = await http.get(
      Uri.parse(
        '$baseUrl/player_api.php?username=${playlist.username}&password=${playlist.password}&action=get_vod_streams',
      ),
    );

    if (moviesResponse.statusCode != 200) {
      throw Exception('Failed to load movies: ${moviesResponse.statusCode}');
    }

    final moviesJson = json.decode(moviesResponse.body);
    final movies = <Movie>[];

    for (final movieData in moviesJson) {
      // Extract container extension from the API response or default to mp4
      final containerExtension = movieData['container_extension'] ?? 'mp4';

      final streamUrl =
          '$baseUrl/movie/${playlist.username}/${playlist.password}/${movieData['stream_id']}.$containerExtension';

      final movie = Movie(
        name: movieData['name'],
        streamUrl: streamUrl,
        coverUrl: movieData['stream_icon'],
        description: movieData['plot'] ?? '',
        year: movieData['year'] ?? '',
        duration: movieData['duration'] ?? '',
        rating: movieData['rating'] ?? '',
        streamId: movieData['stream_id'].toString(),
        tmdbId: movieData['tmdb']?.toString(),
      );

      movie.playlist.target = playlist;

      final categoryId = movieData['category_id'].toString();
      if (categoryMap.containsKey(categoryId)) {
        movie.category.target = categoryMap[categoryId];
      }

      movies.add(movie);
    }

    return {'movies': movies, 'categories': categories};
  }

  Future<Map<String, dynamic>> _fetchSeriesData(
    String baseUrl,
    Playlist playlist,
  ) async {
    // Fetch series categories
    final categoriesResponse = await http.get(
      Uri.parse(
        '$baseUrl/player_api.php?username=${playlist.username}&password=${playlist.password}&action=get_series_categories',
      ),
    );

    if (categoriesResponse.statusCode != 200) {
      throw Exception(
        'Failed to load series categories: ${categoriesResponse.statusCode}',
      );
    }

    final categoriesJson = json.decode(categoriesResponse.body);
    final categories = <Category>[];
    final categoryMap = <String, Category>{};

    for (final categoryData in categoriesJson) {
      final category = Category(
        name: categoryData['category_name'],
        contentType: ContentType.series,
      );
      category.playlist.target = playlist;
      categories.add(category);
      categoryMap[categoryData['category_id'].toString()] = category;
    }

    // Fetch series list
    final seriesListResponse = await http.get(
      Uri.parse(
        '$baseUrl/player_api.php?username=${playlist.username}&password=${playlist.password}&action=get_series',
      ),
    );

    if (seriesListResponse.statusCode != 200) {
      throw Exception(
        'Failed to load series list: ${seriesListResponse.statusCode}',
      );
    }

    final seriesListJson = json.decode(seriesListResponse.body);
    final seriesList = <TvSeries>[];

    for (final seriesData in seriesListJson) {
      final series = TvSeries(
        name: seriesData['name'],
        coverUrl: seriesData['cover'],
        description: seriesData['plot'] ?? '',
        year: seriesData['year'] ?? '',
        rating: seriesData['rating'] ?? '',
        seriesId: seriesData['series_id'].toString(),
        tmdbId: seriesData['tmdb']?.toString(),
      );

      series.playlist.target = playlist;

      final categoryId = seriesData['category_id'].toString();
      if (categoryMap.containsKey(categoryId)) {
        series.category.target = categoryMap[categoryId];
      }

      // We'll fetch episodes for each series when needed to avoid too many API calls at once
      seriesList.add(series);
    }

    return {'series': seriesList, 'categories': categories};
  }

  Future<List<TvEpisode>> fetchSeriesEpisodes(
    String baseUrl,
    Playlist playlist,
    TvSeries series,
  ) async {
    if (series.seriesId == null) {
      return [];
    }

    // Fetch series info with episodes
    final seriesInfoResponse = await http.get(
      Uri.parse(
        '$baseUrl/player_api.php?username=${playlist.username}&password=${playlist.password}&action=get_series_info&series_id=${series.seriesId}',
      ),
    );

    if (seriesInfoResponse.statusCode != 200) {
      throw Exception(
        'Failed to load series info: ${seriesInfoResponse.statusCode}',
      );
    }

    final seriesInfoJson = json.decode(seriesInfoResponse.body);
    final episodes = <TvEpisode>[];

    if (seriesInfoJson.containsKey('episodes') &&
        seriesInfoJson['episodes'] is Map) {
      final episodesMap = seriesInfoJson['episodes'] as Map<String, dynamic>;

      episodesMap.forEach((seasonKey, seasonData) {
        final seasonNumber =
            int.tryParse(seasonKey.replaceAll('season_', '')) ?? 0;

        if (seasonData is List) {
          for (final episodeData in seasonData) {
            try {
              // Make sure episodeData is a Map
              if (episodeData is! Map) continue;

              final episodeNumber =
                  int.tryParse(episodeData['episode_num']?.toString() ?? '0') ??
                  0;

              // Make sure id exists and can be converted to string
              if (episodeData['id'] == null) continue;

              // Extract container extension from the API response or default to mp4
              final containerExtension =
                  episodeData['container_extension'] ?? 'mp4';

              final streamUrl =
                  '$baseUrl/series/${playlist.username}/${playlist.password}/${episodeData['id']}.$containerExtension';

              // Safely access nested properties with null checks
              String? coverUrl;
              String? description;
              String? duration;

              if (episodeData.containsKey('info') &&
                  episodeData['info'] is Map) {
                final info = episodeData['info'] as Map;
                coverUrl = info['movie_image']?.toString();
                description = info['plot']?.toString() ?? '';
                duration = info['duration']?.toString() ?? '';
              }

              final episode = TvEpisode(
                title:
                    episodeData['title']?.toString() ??
                    'Episode $episodeNumber',
                streamUrl: streamUrl,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                coverUrl: coverUrl ?? series.coverUrl,
                description: description ?? '',
                duration: duration ?? '',
                streamId: episodeData['id'].toString(),
              );

              episode.series.target = series;
              episodes.add(episode);
            } catch (e) {
              // Log error but continue to the next episode
              // Using a silent catch to avoid crashing the app
              continue;
            }
          }
        }
      });
    }

    return episodes;
  }
}
