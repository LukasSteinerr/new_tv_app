import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml_parser;
import '../models/epg_channel_info.dart';
import '../models/tv_program.dart';
import 'epg_service.dart'; // Assuming EpgService has the parsing logic

class EpgParserService {
  static Future<Map<String, dynamic>> parseEpgDataIsolate(String epgUrl) async {
    print('Fetching EPG data from in isolate: $epgUrl');
    try {
      final response = await http.get(Uri.parse(epgUrl));
      if (response.statusCode == 200) {
        final xmlString = response.body;

        // Parse EpgChannelInfo
        final document = xml_parser.XmlDocument.parse(xmlString);
        final channelsXml = document.findAllElements('channel');
        final uniqueEpgInfosMap = <String, EpgChannelInfo>{};

        for (final channelElement in channelsXml) {
          final xmlTvId = channelElement.getAttribute('id');
          final displayNameElement =
              channelElement.findElements('display-name').firstOrNull;
          final iconElement = channelElement.findElements('icon').firstOrNull;

          if (xmlTvId != null &&
              xmlTvId.isNotEmpty &&
              displayNameElement != null) {
            final displayName = displayNameElement.innerText;
            final iconUrl = iconElement?.getAttribute('src');
            uniqueEpgInfosMap[xmlTvId] = EpgChannelInfo(
              xmlTvId: xmlTvId,
              displayName: displayName,
              iconUrl: iconUrl,
            );
          }
        }
        final epgChannelInfos = uniqueEpgInfosMap.values.toList();

        // Parse TvProgram data
        final EpgService epgService = EpgService();
        final List<TvProgram> tvPrograms = epgService.parseTvProgramsFromXml(
          xmlString,
        );

        return {'epgChannelInfos': epgChannelInfos, 'tvPrograms': tvPrograms};
      } else {
        print(
          'Failed to load EPG data in isolate: ${response.statusCode} ${response.reasonPhrase}',
        );
        throw Exception('Failed to load EPG data');
      }
    } catch (e) {
      print('Error parsing EPG XML in isolate: $e');
      throw Exception('Error parsing EPG XML');
    }
  }
}
