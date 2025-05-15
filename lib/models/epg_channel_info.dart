import 'package:objectbox/objectbox.dart';

@Entity()
class EpgChannelInfo {
  @Id()
  int id = 0;

  @Unique()
  String xmlTvId; // From <channel id="...">

  String displayName;
  String? iconUrl;

  EpgChannelInfo({
    this.id = 0,
    required this.xmlTvId,
    required this.displayName,
    this.iconUrl,
  });
}
