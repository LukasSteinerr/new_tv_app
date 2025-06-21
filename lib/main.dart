import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart'; // Import logging
import 'services/objectbox_service.dart';
import 'services/playlist_service.dart';
import 'screens/home_screen.dart';
import 'package:background_downloader/background_downloader.dart';

final _log = Logger('MainApp'); // Add logger

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Configure and start background_downloader
  await FileDownloader().configure(
    androidConfig: (Config.runInForeground, true),
  );

  // Configure notifications for the default group
  FileDownloader().configureNotificationForGroup(
    FileDownloader.defaultGroup,
    running: const TaskNotification(
      'Download {filename}',
      'File: {filename} - {progress} - speed {networkSpeed} and {timeRemaining} remaining',
    ),
    complete: const TaskNotification(
      '{displayName} download {filename}',
      'Download complete',
    ),
    error: const TaskNotification('Download {filename}', 'Download failed'),
    paused: const TaskNotification(
      'Download {filename}',
      'Paused with metadata {metadata}',
    ),
    canceled: const TaskNotification('Download {filename}', 'Canceled'),
    progressBar: true,
  );

  // Initialize ObjectBox
  final objectBoxService = await ObjectBoxService.create();
  final playlistService = PlaylistService(objectBoxService);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Register the background download callback
  FileDownloader().registerCallbacks(
    taskNotificationTapCallback: myNotificationTapCallback,
    // You can also register other callbacks here, e.g., for progress updates
    // or when a task completes.
  );

  // Start the FileDownloader
  await FileDownloader().start();
  _log.info('FileDownloader started in main'); // Log FileDownloader start

  runApp(MyApp(playlistService: playlistService));
}

/// Process the user tapping on a notification by printing a message
@pragma('vm:entry-point')
void myNotificationTapCallback(Task task, NotificationType notificationType) {
  _log.info(
    'Tapped notification $notificationType for taskId ${task.taskId}',
  ); // Log notification taps
  debugPrint('Tapped notification $notificationType for taskId ${task.taskId}');
}

class MyApp extends StatelessWidget {
  final PlaylistService playlistService;

  const MyApp({super.key, required this.playlistService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Player',
      theme: ThemeData.dark(),
      darkTheme: ThemeData.dark(),
      home: HomeScreen(playlistService: playlistService),
    );
  }
}
