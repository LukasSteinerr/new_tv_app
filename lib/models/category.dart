import 'package:objectbox/objectbox.dart';
import 'playlist.dart';
import 'channel.dart';
import 'movie.dart';
import 'tv_series.dart';

// Define content types as constants
class ContentType {
  static const int liveTV = 0;
  static const int movie = 1;
  static const int series = 2;
}

@Entity()
class Category {
  @Id()
  int id = 0;

  String name;

  // Content type: 0 = Live TV, 1 = Movies, 2 = Series
  int contentType;

  final playlist = ToOne<Playlist>();

  @Backlink('category')
  final channels = ToMany<Channel>();

  @Backlink('category')
  final movies = ToMany<Movie>();

  @Backlink('category')
  final tvSeries = ToMany<TvSeries>();

  Category({required this.name, this.contentType = ContentType.liveTV});

  // Helper methods
  bool get isLiveTV => contentType == ContentType.liveTV;
  bool get isMovie => contentType == ContentType.movie;
  bool get isSeries => contentType == ContentType.series;
}
