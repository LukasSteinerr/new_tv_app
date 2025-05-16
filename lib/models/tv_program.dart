import 'package:objectbox/objectbox.dart';

@Entity()
class TvProgram {
  @Id()
  int id = 0;

  // This ID links to the 'id' attribute of the <channel> tag in the XML,
  // which should correspond to EpgChannelInfo.xmlTvId
  @Index() // Indexing for faster queries by channel
  String channelXmlTvId;

  String title;
  String? description;

  @Property(type: PropertyType.date) // Stored as milliseconds since epoch
  DateTime startTime;

  @Property(type: PropertyType.date) // Stored as milliseconds since epoch
  DateTime stopTime;

  // You could add more fields here if available in your XML and needed, e.g.:
  // String? iconUrl; // If programmes have specific icons
  // List<String>? categories; // For genres
  // String? episodeNum; // For series episodes

  TvProgram({
    this.id = 0,
    required this.channelXmlTvId,
    required this.title,
    this.description,
    required this.startTime,
    required this.stopTime,
  });

  @override
  String toString() {
    return 'TvProgram{id: $id, channelXmlTvId: $channelXmlTvId, title: "$title", startTime: $startTime, stopTime: $stopTime}';
  }
}
