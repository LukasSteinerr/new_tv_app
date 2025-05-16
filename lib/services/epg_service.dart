import 'package:xml/xml.dart' as xml;
// For robust date parsing, if needed.
import '../models/tv_program.dart';
import 'dart:developer' as developer;

class EpgService {
  // Helper function to parse XMLTV date strings
  // Format: YYYYMMDDHHMMSS ZZZZ (e.g., "20250512230500 +0200")
  DateTime? _parseXmlTvDate(String dateString) {
    if (dateString.length < 14) {
      developer.log(
        'Invalid date string format: $dateString',
        name: 'EpgService.ParseDate',
      );
      return null;
    }

    try {
      final year = int.parse(dateString.substring(0, 4));
      final month = int.parse(dateString.substring(4, 6));
      final day = int.parse(dateString.substring(6, 8));
      final hour = int.parse(dateString.substring(8, 10));
      final minute = int.parse(dateString.substring(10, 12));
      final second = int.parse(dateString.substring(12, 14));

      // Basic DateTime object in local time (will be adjusted by offset if present)
      DateTime dateTime = DateTime(year, month, day, hour, minute, second);

      // Handle timezone offset if present
      if (dateString.length > 15 &&
          (dateString[14] == '+' || dateString[14] == '-')) {
        final offsetSign = dateString[14] == '+' ? 1 : -1;
        final offsetHours = int.parse(dateString.substring(15, 17));
        final offsetMinutes = int.parse(dateString.substring(17, 19));
        final offsetDuration = Duration(
          hours: offsetHours,
          minutes: offsetMinutes,
        );

        // Convert to UTC then apply offset to get the correct local time
        // Or, more simply, adjust the local time by the inverse of the offset to get UTC,
        // then store as UTC. ObjectBox stores dates as UTC milliseconds.
        if (offsetSign == 1) {
          dateTime = dateTime.subtract(
            offsetDuration,
          ); // If +0200, subtract to get UTC
        } else {
          dateTime = dateTime.add(offsetDuration); // If -0200, add to get UTC
        }
      }
      // Return as UTC. ObjectBox handles conversion to/from local time if needed during display.
      return dateTime.toUtc();
    } catch (e) {
      developer.log(
        'Error parsing date string "$dateString": $e',
        name: 'EpgService.ParseDate',
      );
      return null;
    }
  }

  List<TvProgram> parseTvProgramsFromXml(String xmlString) {
    final List<TvProgram> programs = [];
    try {
      final document = xml.XmlDocument.parse(xmlString);
      final programmeElements = document.findAllElements('programme');

      for (final programmeElement in programmeElements) {
        final channelId = programmeElement.getAttribute('channel');
        final startStr = programmeElement.getAttribute('start');
        final stopStr = programmeElement.getAttribute('stop');

        final titleElement = programmeElement.findElements('title').firstOrNull;
        final descElement = programmeElement.findElements('desc').firstOrNull;

        if (channelId == null ||
            channelId.isEmpty ||
            startStr == null ||
            stopStr == null ||
            titleElement == null) {
          developer.log(
            'Skipping programme due to missing essential attributes/elements.',
            name: 'EpgService',
          );
          continue;
        }

        final title = titleElement.innerText;
        final description = descElement?.innerText;

        final startTime = _parseXmlTvDate(startStr);
        final stopTime = _parseXmlTvDate(stopStr);

        if (startTime == null || stopTime == null) {
          developer.log(
            'Skipping programme for channel "$channelId" due to invalid start/stop time.',
            name: 'EpgService',
          );
          continue;
        }

        programs.add(
          TvProgram(
            channelXmlTvId: channelId,
            title: title,
            description: description,
            startTime: startTime,
            stopTime: stopTime,
          ),
        );
      }
    } catch (e) {
      developer.log(
        'Error parsing XMLTV data: $e',
        name: 'EpgService.ParseXml',
      );
      // Depending on requirements, you might want to throw the error,
      // return an empty list, or handle it differently.
    }
    developer.log('Parsed ${programs.length} programs.', name: 'EpgService');
    return programs;
  }
}
