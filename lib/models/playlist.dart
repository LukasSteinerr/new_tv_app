import 'package:objectbox/objectbox.dart';
import 'channel.dart';
import 'category.dart';

// Define playlist types as constants
class PlaylistTypeConstants {
  static const int m3u = 0;
  static const int xtream = 1;
}

@Entity()
class Playlist {
  @Id()
  int id = 0;

  String name;
  String url;
  String? username;
  String? password;

  // Store type as int
  int typeInt;

  @Property(type: PropertyType.date)
  DateTime lastUpdated;

  @Backlink('playlist')
  final channels = ToMany<Channel>();

  @Backlink('playlist')
  final categories = ToMany<Category>();

  // Helper methods for type
  bool get isM3u => typeInt == PlaylistTypeConstants.m3u;
  bool get isXtream => typeInt == PlaylistTypeConstants.xtream;
  String get typeName => isM3u ? 'M3U' : 'Xtream';

  Playlist({
    required this.name,
    required this.url,
    this.username,
    this.password,
    required this.typeInt,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Factory constructors for convenience
  factory Playlist.m3u({
    required String name,
    required String url,
    DateTime? lastUpdated,
  }) {
    return Playlist(
      name: name,
      url: url,
      typeInt: PlaylistTypeConstants.m3u,
      lastUpdated: lastUpdated,
    );
  }

  factory Playlist.xtream({
    required String name,
    required String url,
    required String username,
    required String password,
    DateTime? lastUpdated,
  }) {
    return Playlist(
      name: name,
      url: url,
      username: username,
      password: password,
      typeInt: PlaylistTypeConstants.xtream,
      lastUpdated: lastUpdated,
    );
  }
}
