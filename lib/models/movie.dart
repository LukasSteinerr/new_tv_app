import 'package:objectbox/objectbox.dart';
import 'playlist.dart';
import 'category.dart';
import 'cast.dart';

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
  String? posterUrl; // Added for TMDB poster
  String? backdropUrl; // Added for TMDB backdrop
  String? trailer;
  String? added;
  double? rating_5based;
  int? myList;
  bool isFeatured; // Added to track featured/popular movies

  @Transient()
  List<Cast>? cast;

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
    this.posterUrl, // Added to constructor
    this.backdropUrl, // Added to constructor
    this.trailer,
    this.added,
    this.rating_5based,
    this.myList,
    this.isFeatured = false, // Default to false
    this.cast,
  });
}
