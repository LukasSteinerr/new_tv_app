import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../models/tv_episode.dart';
import '../objectbox.g.dart';

class ObjectBoxService {
  static ObjectBoxService? _instance;
  late final Store _store;
  late final Box<Playlist> _playlistBox;
  late final Box<Channel> _channelBox;
  late final Box<Category> _categoryBox;
  late final Box<Movie> _movieBox;
  late final Box<TvSeries> _tvSeriesBox;
  late final Box<TvEpisode> _tvEpisodeBox;

  ObjectBoxService._create(this._store) {
    _playlistBox = Box<Playlist>(_store);
    _channelBox = Box<Channel>(_store);
    _categoryBox = Box<Category>(_store);
    _movieBox = Box<Movie>(_store);
    _tvSeriesBox = Box<TvSeries>(_store);
    _tvEpisodeBox = Box<TvEpisode>(_store);
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
  List<Playlist> getAllPlaylists() {
    return _playlistBox.getAll();
  }

  int addPlaylist(Playlist playlist) {
    return _playlistBox.put(playlist);
  }

  bool deletePlaylist(int id) {
    return _playlistBox.remove(id);
  }

  Playlist? getPlaylist(int id) {
    return _playlistBox.get(id);
  }

  // Channel operations
  List<Channel> getAllChannels() {
    return _channelBox.getAll();
  }

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

  int addChannel(Channel channel) {
    return _channelBox.put(channel);
  }

  void addChannels(List<Channel> channels) {
    _channelBox.putMany(channels);
  }

  bool deleteChannel(int id) {
    return _channelBox.remove(id);
  }

  // Category operations
  List<Category> getAllCategories() {
    return _categoryBox.getAll();
  }

  List<Category> getCategoriesByPlaylist(int playlistId) {
    final query =
        _categoryBox.query(Category_.playlist.equals(playlistId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  int addCategory(Category category) {
    return _categoryBox.put(category);
  }

  void addCategories(List<Category> categories) {
    _categoryBox.putMany(categories);
  }

  bool deleteCategory(int id) {
    return _categoryBox.remove(id);
  }

  // Movie operations
  List<Movie> getAllMovies() {
    return _movieBox.getAll();
  }

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

  int addMovie(Movie movie) {
    return _movieBox.put(movie);
  }

  void addMovies(List<Movie> movies) {
    _movieBox.putMany(movies);
  }

  bool deleteMovie(int id) {
    return _movieBox.remove(id);
  }

  // TV Series operations
  List<TvSeries> getAllTvSeries() {
    return _tvSeriesBox.getAll();
  }

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

  int addTvSeries(TvSeries series) {
    return _tvSeriesBox.put(series);
  }

  void addTvSeriesList(List<TvSeries> seriesList) {
    _tvSeriesBox.putMany(seriesList);
  }

  bool deleteTvSeries(int id) {
    return _tvSeriesBox.remove(id);
  }

  // TV Episode operations
  List<TvEpisode> getEpisodesBySeries(int seriesId) {
    final query =
        _tvEpisodeBox.query(TvEpisode_.series.equals(seriesId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  int addTvEpisode(TvEpisode episode) {
    return _tvEpisodeBox.put(episode);
  }

  void addTvEpisodes(List<TvEpisode> episodes) {
    _tvEpisodeBox.putMany(episodes);
  }

  bool deleteTvEpisode(int id) {
    return _tvEpisodeBox.remove(id);
  }

  // Close the store when done
  void close() {
    _store.close();
  }
}
