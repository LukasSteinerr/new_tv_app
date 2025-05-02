import 'package:objectbox/objectbox.dart';
import 'playlist.dart';
import 'category.dart';

@Entity()
class Channel {
  @Id()
  int id = 0;

  String name;
  String streamUrl;
  String? logoUrl;
  String? epgId;
  
  final category = ToOne<Category>();
  final playlist = ToOne<Playlist>();

  Channel({
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.epgId,
  });
}
