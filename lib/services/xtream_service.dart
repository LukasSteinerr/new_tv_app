import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;
// Aliased to avoid conflict
import 'package:flutter/foundation.dart' hide Category; // Added for compute
import '../models/epg_channel_info.dart';
import '../models/tv_program.dart'; // Added TvProgram model
import '../services/objectbox_service.dart';
import '../services/epg_service.dart'; // Added EpgService
import '../services/epg_parser_service.dart'; // Added EpgParserService
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../models/tv_episode.dart';

class XtreamService {
  final ObjectBoxService _objectBoxService;
  final EpgService _epgService = EpgService(); // Instantiate EpgService

  XtreamService(this._objectBoxService);

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

      // Fetch and store EPG data
      try {
        await fetchAndStoreEpgData(baseUrl, playlist);
      } catch (e) {
        // Log EPG fetching error but don't let it break the whole process
        print('Error fetching or storing EPG data: $e');
      }

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
      try {
        final streamUrl =
            '$baseUrl/live/${playlist.username}/${playlist.password}/${channelData['stream_id']}.ts';

        final channel = Channel(
          name: channelData['name'],
          streamUrl: streamUrl,
          logoUrl: safeToString(channelData['stream_icon']),
          epgId: safeToString(channelData['epg_channel_id']),
        );

        channel.playlist.target = playlist;

        final categoryId = safeToString(channelData['category_id']);
        if (categoryId != null && categoryMap.containsKey(categoryId)) {
          channel.category.target = categoryMap[categoryId];
        }

        channels.add(channel);
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(
          e,
          s,
          reason: 'Failed to parse channel data',
          information: ['Problematic channelData: ${channelData.toString()}'],
        );
        continue;
      }
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
      try {
        // Extract container extension from the API response or default to mp4
        final containerExtension = movieData['container_extension'] ?? 'mp4';

        final streamUrl =
            '$baseUrl/movie/${playlist.username}/${playlist.password}/${movieData['stream_id']}.$containerExtension';

        final movie = Movie(
          name: movieData['name'],
          streamUrl: streamUrl,
          coverUrl: safeToString(movieData['stream_icon']),
          description: safeToString(movieData['plot']) ?? '',
          year: safeToString(movieData['year']) ?? '',
          duration: safeToString(movieData['duration']) ?? '',
          rating: safeToString(movieData['rating']) ?? '',
          streamId: safeToString(movieData['stream_id'])!,
          tmdbId: safeToString(movieData['tmdb']),
          trailer: safeToString(movieData['trailer']),
          added: safeToString(movieData['added']),
          rating_5based: _parseRating5Based(movieData['rating_5based']),
        );

        movie.playlist.target = playlist;

        final categoryId = safeToString(movieData['category_id']);
        if (categoryId != null && categoryMap.containsKey(categoryId)) {
          movie.category.target = categoryMap[categoryId];
        }

        movies.add(movie);
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(
          e,
          s,
          reason: 'Failed to parse movie data',
          information: ['Problematic movieData: ${movieData.toString()}'],
        );
        continue;
      }
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
      try {
        final series = TvSeries(
          name: seriesData['name'],
          coverUrl: safeToString(seriesData['cover']),
          description: safeToString(seriesData['plot']) ?? '',
          year: safeToString(seriesData['year']) ?? '',
          rating: safeToString(seriesData['rating']) ?? '',
          seriesId: safeToString(seriesData['series_id'])!,
          tmdbId: safeToString(seriesData['tmdb']),
        );

        series.playlist.target = playlist;

        final categoryId = safeToString(seriesData['category_id']);
        if (categoryId != null && categoryMap.containsKey(categoryId)) {
          series.category.target = categoryMap[categoryId];
        }

        // We'll fetch episodes for each series when needed to avoid too many API calls at once
        seriesList.add(series);
      } catch (e, s) {
        FirebaseCrashlytics.instance.recordError(
          e,
          s,
          reason: 'Failed to parse series data',
          information: ['Problematic seriesData: ${seriesData.toString()}'],
        );
        continue;
      }
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
                coverUrl = safeToString(info['movie_image']);
                description = safeToString(info['plot']) ?? '';
                duration = safeToString(info['duration']) ?? '';
              }

              final episode = TvEpisode(
                title:
                    safeToString(episodeData['title']) ??
                    'Episode $episodeNumber',
                streamUrl: streamUrl,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                coverUrl: coverUrl ?? series.coverUrl,
                description: description ?? '',
                duration: duration ?? '',
                streamId: safeToString(episodeData['id'])!,
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

  Future<void> fetchAndStoreEpgData(String baseUrl, Playlist playlist) async {
    if (playlist.username == null || playlist.password == null) {
      print('Username or password missing, skipping EPG fetch.');
      return;
    }

    final epgUrl =
        '$baseUrl/xmltv.php?username=${playlist.username}&password=${playlist.password}';
    print('Fetching EPG data from: $epgUrl');

    try {
      final parsedData = await compute(
        EpgParserService.parseEpgDataIsolate,
        epgUrl,
      );

      final epgChannelInfos =
          parsedData['epgChannelInfos'] as List<EpgChannelInfo>;
      final tvPrograms = parsedData['tvPrograms'] as List<TvProgram>;

      if (epgChannelInfos.isNotEmpty) {
        await _objectBoxService.storeEpgChannelInfos(epgChannelInfos);
        print(
          'Successfully stored ${epgChannelInfos.length} unique EPG channels.',
        );
      } else {
        print(
          'No EPG channel information found in the XML for EpgChannelInfo.',
        );
      }

      _objectBoxService.deleteAllTvPrograms();

      if (tvPrograms.isNotEmpty) {
        await _objectBoxService.addTvProgramsWithYielding(tvPrograms);
        print('Successfully stored ${tvPrograms.length} TV programs.');
      } else {
        print('No TV program data found in the XML.');
      }
    } catch (e) {
      print('Error parsing EPG XML or storing data: $e');
      // Optionally rethrow or handle more gracefully
    }
  }

  double? _parseRating5Based(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Safely converts a dynamic value to a String?.
  /// Handles cases where the value might be a num (int or double) or null.
  String? safeToString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is num) {
      return value.toString();
    }
    return null; // For any other unexpected type
  }
}
