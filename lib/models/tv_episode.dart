import 'package:objectbox/objectbox.dart';
import 'tv_series.dart';

@Entity()
class TvEpisode {
  @Id()
  int id = 0;

  String title;
  String streamUrl;
  int seasonNumber;
  int episodeNumber;
  String? coverUrl;
  String? description;
  String? duration;
  String? streamId;
  
  final series = ToOne<TvSeries>();

  TvEpisode({
    required this.title,
    required this.streamUrl,
    required this.seasonNumber,
    required this.episodeNumber,
    this.coverUrl,
    this.description,
    this.duration,
    this.streamId,
  });
}
