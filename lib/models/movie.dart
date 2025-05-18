import 'package:objectbox/objectbox.dart';
import 'playlist.dart';
import 'category.dart';

@Entity()
class Movie {
  @Id()
  int id = 0;

  String name;
  String streamUrl;
  String? coverUrl;
  String? description;
  String? year;
  String? duration;
  String? rating;
  String? streamId;
  String? tmdbId;
  String? trailer;
  String? added;
  double? rating_5based;

  final category = ToOne<Category>();
  final playlist = ToOne<Playlist>();

  Movie({
    required this.name,
    required this.streamUrl,
    this.coverUrl,
    this.description,
    this.year,
    this.duration,
    this.rating,
    this.streamId,
    this.tmdbId,
    this.trailer,
    this.added,
    this.rating_5based,
  });
}
