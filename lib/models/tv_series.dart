import 'package:objectbox/objectbox.dart';
import 'playlist.dart';
import 'category.dart';
import 'tv_episode.dart';

@Entity()
class TvSeries {
  @Id()
  int id = 0;

  String name;
  String? coverUrl;
  String? description;
  String? year;
  String? rating;
  String? seriesId;
  
  final category = ToOne<Category>();
  final playlist = ToOne<Playlist>();
  
  @Backlink('series')
  final episodes = ToMany<TvEpisode>();

  TvSeries({
    required this.name,
    this.coverUrl,
    this.description,
    this.year,
    this.rating,
    this.seriesId,
  });
}
