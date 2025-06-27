import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../models/tv_episode.dart';
import '../models/epg_channel_info.dart';
import '../models/tv_program.dart';
import '../objectbox.g.dart';
import 'dart:developer' as developer;

class ObjectBoxService {
  static ObjectBoxService? _instance;
  late final Store _store;
  late final Box<Playlist> _playlistBox;
  late final Box<Channel> _channelBox;
  late final Box<Category> _categoryBox;
  late final Box<Movie> _movieBox;
  late final Box<TvSeries> _tvSeriesBox;
  late final Box<TvEpisode> _tvEpisodeBox;
  late final Box<EpgChannelInfo> _epgChannelInfoBox;
  late final Box<TvProgram> _tvProgramBox;

  Admin? _admin;

  ObjectBoxService._create(this._store) {
    _playlistBox = Box<Playlist>(_store);
    _channelBox = Box<Channel>(_store);
    _categoryBox = Box<Category>(_store);
    _movieBox = Box<Movie>(_store);
    _tvSeriesBox = Box<TvSeries>(_store);
    _tvEpisodeBox = Box<TvEpisode>(_store);
    _epgChannelInfoBox = Box<EpgChannelInfo>(_store);
    _tvProgramBox = Box<TvProgram>(_store);

    final isAdminAvailable = Admin.isAvailable();
    developer.log(
      'Admin.isAvailable(): $isAdminAvailable',
      name: 'ObjectBoxService',
    );
    if (isAdminAvailable) {
      try {
        _admin = Admin(_store);
        developer.log(
          'Admin initialized. Admin instance: ${_admin != null ? "created" : "null"}',
          name: 'ObjectBoxService',
        );
      } catch (e, s) {
        developer.log(
          'Error initializing Admin: $e',
          name: 'ObjectBoxService',
          error: e,
          stackTrace: s,
        );
      }
    } else {
      developer.log(
        'Admin is not available. Ensure you are in a debug build and native dependencies are correct.',
        name: 'ObjectBoxService',
      );
    }
  }

  static Future<ObjectBoxService> create() async {
    if (_instance == null) {
      final docsDir = await getApplicationDocumentsDirectory();
      final store = await openStore(directory: p.join(docsDir.path, "iptv-db"));
      _instance = ObjectBoxService._create(store);
    }
    return _instance!;
  }

  // Playlist operations
  List<Playlist> getAllPlaylists() => _playlistBox.getAll();
  int addPlaylist(Playlist playlist) => _playlistBox.put(playlist);
  bool deletePlaylist(int id) => _playlistBox.remove(id);
  Playlist? getPlaylist(int id) => _playlistBox.get(id);

  // Channel operations
  List<Channel> getAllChannels() => _channelBox.getAll();
  List<Channel> getChannelsByPlaylist(int playlistId) {
    final query =
        _channelBox.query(Channel_.playlist.equals(playlistId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<Channel> getChannelsByCategory(int categoryId) {
    final query =
        _channelBox.query(Channel_.category.equals(categoryId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  int addChannel(Channel channel) => _channelBox.put(channel);
  void addChannels(List<Channel> channels) => _channelBox.putMany(channels);
  bool deleteChannel(int id) => _channelBox.remove(id);

  // Category operations
  List<Category> getAllCategories() => _categoryBox.getAll();
  List<Category> getCategoriesByPlaylist(int playlistId) {
    final query =
        _categoryBox.query(Category_.playlist.equals(playlistId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  int addCategory(Category category) => _categoryBox.put(category);
  void addCategories(List<Category> categories) =>
      _categoryBox.putMany(categories);
  bool deleteCategory(int id) => _categoryBox.remove(id);

  // Movie operations
  List<Movie> getAllMovies() => _movieBox.getAll();
  List<Movie> getMoviesByPlaylist(int playlistId) {
    final query = _movieBox.query(Movie_.playlist.equals(playlistId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<Movie> getMoviesByCategory(int categoryId) {
    final query = _movieBox.query(Movie_.category.equals(categoryId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  int addMovie(Movie movie) => _movieBox.put(movie);
  void addMovies(List<Movie> movies) => _movieBox.putMany(movies);
  bool deleteMovie(int id) => _movieBox.remove(id);

  Movie? getMovieByTmdbId(String tmdbId) {
    final query = _movieBox.query(Movie_.tmdbId.equals(tmdbId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  // Get featured movies by playlist
  List<Movie> getFeaturedMoviesByPlaylist(int playlistId) {
    final query =
        _movieBox
            .query(
              Movie_.playlist.equals(playlistId) &
                  Movie_.isFeatured.equals(true),
            )
            .build();
    final results = query.find();
    query.close();
    return results;
  }

  // Clear featured status for all movies in a playlist
  void clearFeaturedMoviesForPlaylist(int playlistId) {
    final movies = getMoviesByPlaylist(playlistId);
    for (final movie in movies) {
      if (movie.isFeatured) {
        movie.isFeatured = false;
        _movieBox.put(movie);
      }
    }
  }

  // Update featured status for multiple movies
  void updateMoviesFeaturedStatus(List<Movie> movies, bool isFeatured) {
    for (final movie in movies) {
      movie.isFeatured = isFeatured;
    }
    _movieBox.putMany(movies);
  }

  // TV Series operations
  List<TvSeries> getAllTvSeries() => _tvSeriesBox.getAll();
  List<TvSeries> getTvSeriesByPlaylist(int playlistId) {
    final query =
        _tvSeriesBox.query(TvSeries_.playlist.equals(playlistId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  List<TvSeries> getTvSeriesByCategory(int categoryId) {
    final query =
        _tvSeriesBox.query(TvSeries_.category.equals(categoryId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  int addTvSeries(TvSeries series) => _tvSeriesBox.put(series);
  void addTvSeriesList(List<TvSeries> seriesList) =>
      _tvSeriesBox.putMany(seriesList);
  bool deleteTvSeries(int id) => _tvSeriesBox.remove(id);

  // Get featured TV series by playlist
  List<TvSeries> getFeaturedTvSeriesByPlaylist(int playlistId) {
    final query =
        _tvSeriesBox
            .query(
              TvSeries_.playlist.equals(playlistId) &
                  TvSeries_.isFeatured.equals(true),
            )
            .build();
    final results = query.find();
    query.close();
    return results;
  }

  // Clear featured status for all TV series in a playlist
  void clearFeaturedTvSeriesForPlaylist(int playlistId) {
    final tvSeries = getTvSeriesByPlaylist(playlistId);
    for (final series in tvSeries) {
      if (series.isFeatured) {
        series.isFeatured = false;
        _tvSeriesBox.put(series);
      }
    }
  }

  // Update featured status for multiple TV series
  void updateTvSeriesFeaturedStatus(
    List<TvSeries> seriesList,
    bool isFeatured,
  ) {
    for (final series in seriesList) {
      series.isFeatured = isFeatured;
    }
    _tvSeriesBox.putMany(seriesList);
  }

  // TV Episode operations
  List<TvEpisode> getEpisodesBySeries(int seriesId) {
    final query =
        _tvEpisodeBox.query(TvEpisode_.series.equals(seriesId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  int addTvEpisode(TvEpisode episode) => _tvEpisodeBox.put(episode);
  void addTvEpisodes(List<TvEpisode> episodes) =>
      _tvEpisodeBox.putMany(episodes);
  bool deleteTvEpisode(int id) => _tvEpisodeBox.remove(id);

  // EPG Channel Info operations
  Future<void> storeEpgChannelInfos(
    List<EpgChannelInfo> epgChannelInfos,
  ) async {
    final List<EpgChannelInfo> toPut = [];
    for (var newInfo in epgChannelInfos) {
      final query =
          _epgChannelInfoBox
              .query(EpgChannelInfo_.xmlTvId.equals(newInfo.xmlTvId))
              .build();
      final existingInfo = query.findFirst();
      query.close();
      if (existingInfo != null) {
        existingInfo.displayName = newInfo.displayName;
        existingInfo.iconUrl = newInfo.iconUrl;
        toPut.add(existingInfo);
      } else {
        toPut.add(newInfo);
      }
    }
    if (toPut.isNotEmpty) {
      _epgChannelInfoBox.putMany(toPut);
    }
  }

  List<EpgChannelInfo> getAllEpgChannelInfos() {
    return _epgChannelInfoBox.getAll();
  }

  EpgChannelInfo? getEpgChannelInfoByXmlTvId(String xmlTvId) {
    final query =
        _epgChannelInfoBox
            .query(EpgChannelInfo_.xmlTvId.equals(xmlTvId))
            .build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  // TV Program operations
  void addTvPrograms(List<TvProgram> programs) {
    _tvProgramBox.putMany(programs);
  }

  // Add TV programs in batches with yielding to prevent UI blocking
  Future<void> addTvProgramsWithYielding(List<TvProgram> programs) async {
    const batchSize = 1000; // Process 1000 programs at a time

    for (int i = 0; i < programs.length; i += batchSize) {
      final end =
          (i + batchSize < programs.length) ? i + batchSize : programs.length;
      final batch = programs.sublist(i, end);

      _tvProgramBox.putMany(batch);

      // Yield after each batch to allow UI updates
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  List<TvProgram> getTvProgramsForChannel(String channelXmlTvId) {
    final QueryBuilder<TvProgram> queryBuilder = _tvProgramBox.query(
      TvProgram_.channelXmlTvId.equals(channelXmlTvId),
    );
    queryBuilder.order(TvProgram_.startTime);
    final Query<TvProgram> query = queryBuilder.build();
    final results = query.find();
    query.close();
    return results;
  }

  List<TvProgram> getTvProgramsForChannelInTimeRange(
    String channelXmlTvId,
    DateTime start,
    DateTime end,
  ) {
    final QueryBuilder<TvProgram> queryBuilder = _tvProgramBox.query(
      TvProgram_.channelXmlTvId.equals(channelXmlTvId) &
          TvProgram_.startTime.lessThan(end.millisecondsSinceEpoch) &
          TvProgram_.stopTime.greaterThan(start.millisecondsSinceEpoch),
    );
    queryBuilder.order(TvProgram_.startTime);
    final Query<TvProgram> query = queryBuilder.build();
    final results = query.find();
    query.close();
    return results;
  }

  List<TvProgram> getAllTvPrograms() {
    return _tvProgramBox.getAll();
  }

  void deleteAllTvProgramsForChannel(String channelXmlTvId) {
    final QueryBuilder<TvProgram> queryBuilder = _tvProgramBox.query(
      TvProgram_.channelXmlTvId.equals(channelXmlTvId),
    );
    final Query<TvProgram> query = queryBuilder.build();
    final programsToDelete = query.findIds();
    query.close();
    if (programsToDelete.isNotEmpty) {
      _tvProgramBox.removeMany(programsToDelete);
    }
  }

  void deleteAllTvPrograms() {
    _tvProgramBox.removeAll();
    developer.log('All TV programs deleted.', name: 'ObjectBoxService');
  }

  // Close the store when done
  void close() {
    _admin?.close();
    _store.close();
  }
}
