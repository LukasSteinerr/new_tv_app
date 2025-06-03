import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../models/tv_episode.dart';
import '../models/tv_program.dart'; // Added for TvProgram
import 'objectbox_service.dart';
import 'm3u_service.dart';
import 'xtream_service.dart';

class PlaylistService {
  final ObjectBoxService _objectBoxService;
  final M3uService _m3uService = M3uService();
  final XtreamService _xtreamService;

  PlaylistService(this._objectBoxService)
    : _xtreamService = XtreamService(_objectBoxService);

  Future<List<Playlist>> getAllPlaylists() async {
    return _objectBoxService.getAllPlaylists();
  }

  Future<int> addPlaylist(Playlist playlist) async {
    return _objectBoxService.addPlaylist(playlist);
  }

  Future<bool> deletePlaylist(int id) async {
    return _objectBoxService.deletePlaylist(id);
  }

  Future<void> refreshPlaylist(Playlist playlist) async {
    Map<String, dynamic> result;

    // Delete existing data for this playlist
    final existingCategories = _objectBoxService.getCategoriesByPlaylist(
      playlist.id,
    );
    for (final category in existingCategories) {
      _objectBoxService.deleteCategory(category.id);
    }

    final existingChannels = _objectBoxService.getChannelsByPlaylist(
      playlist.id,
    );
    for (final channel in existingChannels) {
      _objectBoxService.deleteChannel(channel.id);
    }

    // Delete movies if they exist
    try {
      final existingMovies = _objectBoxService.getMoviesByPlaylist(playlist.id);
      for (final movie in existingMovies) {
        _objectBoxService.deleteMovie(movie.id);
      }
    } catch (e) {
      // Ignore if movies don't exist yet
    }

    // Delete TV series if they exist
    try {
      final existingTvSeries = _objectBoxService.getTvSeriesByPlaylist(
        playlist.id,
      );
      for (final series in existingTvSeries) {
        _objectBoxService.deleteTvSeries(series.id);
      }
    } catch (e) {
      // Ignore if TV series don't exist yet
    }

    // Fetch new data based on playlist type
    if (playlist.isM3u) {
      result = await _m3uService.parseM3uPlaylist(playlist);

      // Save new categories and channels
      final categories = result['categories'] as List<Category>;
      _objectBoxService.addCategories(categories);

      final channels = result['channels'] as List<Channel>;
      _objectBoxService.addChannels(channels);
    } else {
      // For Xtream playlists, we get more content types
      result = await _xtreamService.fetchXtreamData(playlist);

      // Save live TV categories and channels
      final liveCategories = result['categories'] as List<Category>;
      _objectBoxService.addCategories(liveCategories);

      final channels = result['channels'] as List<Channel>;
      _objectBoxService.addChannels(channels);

      // Save movie categories and movies
      if (result.containsKey('movieCategories') &&
          result.containsKey('movies')) {
        final movieCategories = result['movieCategories'] as List<Category>;
        _objectBoxService.addCategories(movieCategories);

        final movies = result['movies'] as List<Movie>;
        _objectBoxService.addMovies(movies);
      }

      // Save series categories and series
      if (result.containsKey('seriesCategories') &&
          result.containsKey('series')) {
        final seriesCategories = result['seriesCategories'] as List<Category>;
        _objectBoxService.addCategories(seriesCategories);

        final seriesList = result['series'] as List<TvSeries>;
        _objectBoxService.addTvSeriesList(seriesList);

        // We'll fetch episodes for each series when needed to avoid too many API calls at once
      }
    }

    // Update last updated timestamp
    playlist.lastUpdated = DateTime.now();
    _objectBoxService.addPlaylist(playlist);
  }

  Future<List<Category>> getPlaylistCategories(int playlistId) async {
    return _objectBoxService.getCategoriesByPlaylist(playlistId);
  }

  Future<List<Channel>> getPlaylistChannels(int playlistId) async {
    return _objectBoxService.getChannelsByPlaylist(playlistId);
  }

  Future<List<Channel>> getCategoryChannels(int categoryId) async {
    return _objectBoxService.getChannelsByCategory(categoryId);
  }

  Future<List<Movie>> getPlaylistMovies(int playlistId) async {
    return _objectBoxService.getMoviesByPlaylist(playlistId);
  }

  Future<List<Movie>> getCategoryMovies(int categoryId) async {
    return _objectBoxService.getMoviesByCategory(categoryId);
  }

  Future<List<TvSeries>> getPlaylistTvSeries(int playlistId) async {
    return _objectBoxService.getTvSeriesByPlaylist(playlistId);
  }

  Future<List<TvSeries>> getCategoryTvSeries(int categoryId) async {
    return _objectBoxService.getTvSeriesByCategory(categoryId);
  }

  Future<List<TvEpisode>> getTvSeriesEpisodes(TvSeries series) async {
    final episodes = _objectBoxService.getEpisodesBySeries(series.id);

    // If no episodes are found, try to fetch them from the API
    if (episodes.isEmpty && series.playlist.target != null) {
      final playlist = series.playlist.target!;
      if (!playlist.isM3u &&
          playlist.url.isNotEmpty &&
          series.seriesId != null) {
        final uri = Uri.parse(playlist.url);
        final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';

        try {
          final fetchedEpisodes = await _xtreamService.fetchSeriesEpisodes(
            baseUrl,
            playlist,
            series,
          );

          if (fetchedEpisodes.isNotEmpty) {
            _objectBoxService.addTvEpisodes(fetchedEpisodes);
            return fetchedEpisodes;
          }
        } catch (e) {
          // Rethrow as a more specific exception with context
          throw Exception('Failed to load episodes for ${series.name}: $e');
        }
      }
    }

    return episodes;
  }

  // EPG (TvProgram) operations
  Future<List<TvProgram>> getTvProgramsForChannel(String channelEpgId) async {
    // Ensure channelEpgId is not empty, as ObjectBoxService might not check
    if (channelEpgId.isEmpty) {
      return [];
    }
    return _objectBoxService.getTvProgramsForChannel(channelEpgId);
  }

  Future<List<TvProgram>> getTvProgramsForChannelInTimeRange(
    String channelEpgId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    // Ensure channelEpgId is not empty
    if (channelEpgId.isEmpty) {
      return [];
    }
    return _objectBoxService.getTvProgramsForChannelInTimeRange(
      channelEpgId,
      startTime,
      endTime,
    );
  }
}
