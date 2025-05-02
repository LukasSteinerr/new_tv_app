import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';

class M3uService {
  Future<Map<String, dynamic>> parseM3uPlaylist(Playlist playlist) async {
    try {
      final response = await http.get(Uri.parse(playlist.url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load playlist: ${response.statusCode}');
      }

      final content = utf8.decode(response.bodyBytes);
      return _parseM3uContent(content, playlist);
    } catch (e) {
      throw Exception('Error parsing M3U playlist: $e');
    }
  }

  Map<String, dynamic> _parseM3uContent(String content, Playlist playlist) {
    final lines = content.split('\n');

    if (lines.isEmpty || !lines[0].trim().startsWith('#EXTM3U')) {
      throw Exception('Invalid M3U format');
    }

    final channels = <Channel>[];
    final categories = <String, Category>{};

    String? currentChannelName;
    String? currentGroupTitle;
    String? currentLogoUrl;
    String? currentEpgId;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Parse channel info
        final infoLine = line.substring(line.indexOf(':') + 1);

        // Extract channel name
        final nameMatch = RegExp(',(.*)\$').firstMatch(infoLine);
        if (nameMatch != null) {
          currentChannelName = nameMatch.group(1)?.trim();
        }

        // Extract group-title
        final groupMatch = RegExp('group-title="([^"]*)"').firstMatch(infoLine);
        if (groupMatch != null) {
          currentGroupTitle = groupMatch.group(1)?.trim();
        }

        // Extract tvg-logo
        final logoMatch = RegExp('tvg-logo="([^"]*)"').firstMatch(infoLine);
        if (logoMatch != null) {
          currentLogoUrl = logoMatch.group(1)?.trim();
        }

        // Extract tvg-id
        final epgMatch = RegExp('tvg-id="([^"]*)"').firstMatch(infoLine);
        if (epgMatch != null) {
          currentEpgId = epgMatch.group(1)?.trim();
        }
      } else if (!line.startsWith('#') && currentChannelName != null) {
        // This is a URL line
        final streamUrl = line;

        // Create category if needed
        if (currentGroupTitle != null && currentGroupTitle.isNotEmpty) {
          if (!categories.containsKey(currentGroupTitle)) {
            final category = Category(
              name: currentGroupTitle,
              contentType:
                  ContentType.liveTV, // M3U playlists are treated as Live TV
            );
            category.playlist.target = playlist;
            categories[currentGroupTitle] = category;
          }
        }

        // Create channel
        final channel = Channel(
          name: currentChannelName,
          streamUrl: streamUrl,
          logoUrl: currentLogoUrl,
          epgId: currentEpgId,
        );

        channel.playlist.target = playlist;

        if (currentGroupTitle != null && currentGroupTitle.isNotEmpty) {
          channel.category.target = categories[currentGroupTitle];
        }

        channels.add(channel);

        // Reset for next channel
        currentChannelName = null;
        currentLogoUrl = null;
        currentEpgId = null;
      }
    }

    return {'channels': channels, 'categories': categories.values.toList()};
  }
}
