import '../exceptions/playlist_exception.dart';
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
import 'tmdb_service.dart'; // Added TMDB service

class PlaylistService {
  final ObjectBoxService _objectBoxService;
  final M3uService _m3uService = M3uService();
  final XtreamService _xtreamService;
  final TMDBService _tmdbService = TMDBService(); // Added TMDB service

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

    // Delete existing data for this playlist with yielding
    await _deleteExistingDataWithYielding(playlist);

    // Add a yield point to allow UI updates
    await Future.delayed(const Duration(milliseconds: 10));

    // Fetch new data based on playlist type
    if (playlist.isM3u) {
      result = await _m3uService.parseM3uPlaylist(playlist);

      // Save new categories and channels with yielding
      await _saveCategoriesWithYielding(result['categories'] as List<Category>);
      await _saveChannelsWithYielding(result['channels'] as List<Channel>);
    } else {
      // For Xtream playlists, we get more content types
      result = await _xtreamService.fetchXtreamData(playlist);

      // Save live TV categories and channels with yielding
      await _saveCategoriesWithYielding(result['categories'] as List<Category>);
      await _saveChannelsWithYielding(result['channels'] as List<Channel>);

      // Save movie categories and movies with yielding
      if (result.containsKey('movieCategories') &&
          result.containsKey('movies')) {
        await _saveCategoriesWithYielding(
          result['movieCategories'] as List<Category>,
        );
        await _saveMoviesWithYielding(result['movies'] as List<Movie>);

        // Match TMDB popular movies with local movies after movies are saved
        await _matchTmdbPopularMovies(playlist.id);
      }

      // Save series categories and series with yielding
      if (result.containsKey('seriesCategories') &&
          result.containsKey('series')) {
        await _saveCategoriesWithYielding(
          result['seriesCategories'] as List<Category>,
        );
        await _saveTvSeriesWithYielding(result['series'] as List<TvSeries>);

        // Match TMDB popular TV series with local series after series are saved
        await _matchTmdbPopularTvSeries(playlist.id);
      }
    }

    // Update last updated timestamp
    playlist.lastUpdated = DateTime.now();
    _objectBoxService.addPlaylist(playlist);
  }

  Future<void> fetchAndSavePlaylistData(Playlist playlist) async {
    try {
      Map<String, dynamic> result;

      // Fetch new data based on playlist type
      if (playlist.isM3u) {
        result = await _m3uService.parseM3uPlaylist(playlist);
      } else {
        result = await _xtreamService.fetchXtreamData(playlist);
      }

      // Save the playlist first to get an ID
      final playlistId = _objectBoxService.addPlaylist(playlist);
      playlist.id = playlistId;

      // Save categories and channels
      if (result.containsKey('categories')) {
        final categories = result['categories'] as List<Category>;
        for (var category in categories) {
          category.playlist.target = playlist;
        }
        await _saveCategoriesWithYielding(categories);
      }
      if (result.containsKey('channels')) {
        final channels = result['channels'] as List<Channel>;
        for (var channel in channels) {
          channel.playlist.target = playlist;
        }
        await _saveChannelsWithYielding(channels);
      }

      // Save movies
      if (result.containsKey('movieCategories') &&
          result.containsKey('movies')) {
        final movieCategories = result['movieCategories'] as List<Category>;
        for (var category in movieCategories) {
          category.playlist.target = playlist;
        }
        await _saveCategoriesWithYielding(movieCategories);

        final movies = result['movies'] as List<Movie>;
        for (var movie in movies) {
          movie.playlist.target = playlist;
        }
        await _saveMoviesWithYielding(movies);
        await _matchTmdbPopularMovies(playlist.id);
      }

      // Save TV series
      if (result.containsKey('seriesCategories') &&
          result.containsKey('series')) {
        final seriesCategories = result['seriesCategories'] as List<Category>;
        for (var category in seriesCategories) {
          category.playlist.target = playlist;
        }
        await _saveCategoriesWithYielding(seriesCategories);

        final series = result['series'] as List<TvSeries>;
        for (var s in series) {
          s.playlist.target = playlist;
        }
        await _saveTvSeriesWithYielding(series);
        await _matchTmdbPopularTvSeries(playlist.id);
      }

      // Update last updated timestamp
      playlist.lastUpdated = DateTime.now();
      _objectBoxService.addPlaylist(playlist);
    } on PlaylistException {
      rethrow; // Re-throw PlaylistExceptions directly to preserve specific error messages
    } catch (e) {
      // For any other unexpected errors, wrap them in a generic PlaylistException
      throw PlaylistException(
        'An unexpected error occurred while processing the playlist.',
        e.toString(),
      );
    }
  }

  Future<void> _deleteExistingDataWithYielding(Playlist playlist) async {
    // Delete existing categories with yielding
    final existingCategories = _objectBoxService.getCategoriesByPlaylist(
      playlist.id,
    );
    for (int i = 0; i < existingCategories.length; i++) {
      _objectBoxService.deleteCategory(existingCategories[i].id);

      // Yield every 10 deletions to allow UI updates
      if (i % 10 == 0) {
        await Future.delayed(const Duration(microseconds: 1));
      }
    }

    // Delete existing channels with yielding
    final existingChannels = _objectBoxService.getChannelsByPlaylist(
      playlist.id,
    );
    for (int i = 0; i < existingChannels.length; i++) {
      _objectBoxService.deleteChannel(existingChannels[i].id);

      // Yield every 10 deletions to allow UI updates
      if (i % 10 == 0) {
        await Future.delayed(const Duration(microseconds: 1));
      }
    }

    // Delete movies if they exist with yielding
    try {
      final existingMovies = _objectBoxService.getMoviesByPlaylist(playlist.id);
      for (int i = 0; i < existingMovies.length; i++) {
        _objectBoxService.deleteMovie(existingMovies[i].id);

        // Yield every 10 deletions to allow UI updates
        if (i % 10 == 0) {
          await Future.delayed(const Duration(microseconds: 1));
        }
      }
    } catch (e) {
      // Ignore if movies don't exist yet
    }

    // Delete TV series if they exist with yielding
    try {
      final existingTvSeries = _objectBoxService.getTvSeriesByPlaylist(
        playlist.id,
      );
      for (int i = 0; i < existingTvSeries.length; i++) {
        _objectBoxService.deleteTvSeries(existingTvSeries[i].id);

        // Yield every 10 deletions to allow UI updates
        if (i % 10 == 0) {
          await Future.delayed(const Duration(microseconds: 1));
        }
      }
    } catch (e) {
      // Ignore if TV series don't exist yet
    }
  }

  Future<void> _saveCategoriesWithYielding(List<Category> categories) async {
    const batchSize = 20;
    for (int i = 0; i < categories.length; i += batchSize) {
      final end =
          (i + batchSize < categories.length)
              ? i + batchSize
              : categories.length;
      final batch = categories.sublist(i, end);

      _objectBoxService.addCategories(batch);

      // Yield after each batch to allow UI updates
      await Future.delayed(const Duration(microseconds: 1));
    }
  }

  Future<void> _saveChannelsWithYielding(List<Channel> channels) async {
    const batchSize = 50;
    for (int i = 0; i < channels.length; i += batchSize) {
      final end =
          (i + batchSize < channels.length) ? i + batchSize : channels.length;
      final batch = channels.sublist(i, end);

      _objectBoxService.addChannels(batch);

      // Yield after each batch to allow UI updates
      await Future.delayed(const Duration(microseconds: 1));
    }
  }

  Future<void> _saveMoviesWithYielding(List<Movie> movies) async {
    const batchSize = 100;
    for (int i = 0; i < movies.length; i += batchSize) {
      final end =
          (i + batchSize < movies.length) ? i + batchSize : movies.length;
      final batch = movies.sublist(i, end);

      _objectBoxService.addMovies(batch);

      // Yield after each batch to allow UI updates
      await Future.delayed(const Duration(microseconds: 1));
    }
  }

  Future<void> _saveTvSeriesWithYielding(List<TvSeries> series) async {
    const batchSize = 100;
    for (int i = 0; i < series.length; i += batchSize) {
      final end =
          (i + batchSize < series.length) ? i + batchSize : series.length;
      final batch = series.sublist(i, end);

      _objectBoxService.addTvSeriesList(batch);

      // Yield after each batch to allow UI updates
      await Future.delayed(const Duration(microseconds: 1));
    }
  }

  Future<void> refreshEpgData(Playlist playlist) async {
    if (!playlist.isM3u) {
      final uri = Uri.parse(playlist.url);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      await _xtreamService.fetchAndStoreEpgData(baseUrl, playlist);
    }
    // M3U playlists might have EPG from a separate URL, this could be extended
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

  // Featured movies operations
  Future<List<Movie>> getFeaturedMovies(int playlistId) async {
    return _objectBoxService.getFeaturedMoviesByPlaylist(playlistId);
  }

  // Match TMDB popular movies with local movies and update featured status
  Future<void> _matchTmdbPopularMovies(int playlistId) async {
    try {
      // Clear existing featured status for this playlist
      _objectBoxService.clearFeaturedMoviesForPlaylist(playlistId);

      // Fetch popular TMDB movies
      final popularTmdbMovies = await _tmdbService.getPopularMovies();

      // Get all movies from the local playlist
      final localMovies = await getPlaylistMovies(playlistId);

      // Create a map of local movies by their TMDB ID for easy lookup
      Map<String, Movie> localMoviesByTmdbId = {
        for (var movie in localMovies)
          if (movie.tmdbId != null && movie.tmdbId!.isNotEmpty)
            movie.tmdbId!: movie,
      };

      // Find matching movies and update them with TMDB data
      List<Movie> featuredMovies = [];
      for (var tmdbMovie in popularTmdbMovies) {
        if (localMoviesByTmdbId.containsKey(tmdbMovie.tmdbId)) {
          Movie localMovie = localMoviesByTmdbId[tmdbMovie.tmdbId]!;

          // Update local movie with fresh TMDB data while preserving core identity
          localMovie.name = tmdbMovie.name;
          localMovie.description =
              tmdbMovie.description ?? localMovie.description;
          localMovie.posterUrl = tmdbMovie.posterUrl ?? localMovie.posterUrl;
          localMovie.backdropUrl =
              tmdbMovie.backdropUrl ?? localMovie.backdropUrl;
          localMovie.featuredPosterUrl =
              tmdbMovie.featuredPosterUrl ?? localMovie.featuredPosterUrl;
          localMovie.rating = tmdbMovie.rating ?? localMovie.rating;
          localMovie.year = tmdbMovie.year ?? localMovie.year;
          localMovie.isFeatured = true; // Mark as featured

          featuredMovies.add(localMovie);
        }
      }

      // Save the updated featured movies
      if (featuredMovies.isNotEmpty) {
        _objectBoxService.addMovies(featuredMovies);
      }
    } catch (e) {
      print('Error matching TMDB popular movies: $e');
    }
  }

  // Manually refresh featured movies for a playlist
  Future<void> refreshFeaturedMovies(int playlistId) async {
    await _matchTmdbPopularMovies(playlistId);
  }

  // Featured TV series operations
  Future<List<TvSeries>> getFeaturedTvSeries(int playlistId) async {
    return _objectBoxService.getFeaturedTvSeriesByPlaylist(playlistId);
  }

  // Match TMDB popular TV series with local series and update featured status
  Future<void> _matchTmdbPopularTvSeries(int playlistId) async {
    try {
      // Clear existing featured status for this playlist
      _objectBoxService.clearFeaturedTvSeriesForPlaylist(playlistId);

      // Fetch popular TMDB TV series
      final popularTmdbTvSeries = await _tmdbService.getPopularTvSeries();

      // Get all TV series from the local playlist
      final localTvSeries = await getPlaylistTvSeries(playlistId);

      // Create a map of local TV series by their TMDB ID for easy lookup
      Map<String, TvSeries> localTvSeriesByTmdbId = {
        for (var series in localTvSeries)
          if (series.tmdbId != null && series.tmdbId!.isNotEmpty)
            series.tmdbId!: series,
      };

      // Find matching TV series and update them with TMDB data
      List<TvSeries> featuredTvSeries = [];
      for (var tmdbSeries in popularTmdbTvSeries) {
        if (localTvSeriesByTmdbId.containsKey(tmdbSeries.tmdbId)) {
          TvSeries localSeries = localTvSeriesByTmdbId[tmdbSeries.tmdbId]!;

          // Update local series with fresh TMDB data while preserving core identity
          localSeries.name = tmdbSeries.name;
          localSeries.description =
              tmdbSeries.description ?? localSeries.description;
          localSeries.coverUrl = tmdbSeries.coverUrl ?? localSeries.coverUrl;
          localSeries.featuredPosterUrl =
              tmdbSeries.featuredPosterUrl ?? localSeries.featuredPosterUrl;
          localSeries.rating = tmdbSeries.rating ?? localSeries.rating;
          localSeries.year = tmdbSeries.year ?? localSeries.year;
          localSeries.isFeatured = true; // Mark as featured

          featuredTvSeries.add(localSeries);
        }
      }

      // Save the updated featured TV series
      if (featuredTvSeries.isNotEmpty) {
        _objectBoxService.addTvSeriesList(featuredTvSeries);
      }
    } catch (e) {
      print('Error matching TMDB popular TV series: $e');
    }
  }

  // Manually refresh featured TV series for a playlist
  Future<void> refreshFeaturedTvSeries(int playlistId) async {
    await _matchTmdbPopularTvSeries(playlistId);
  }
}
