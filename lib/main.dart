import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:background_downloader/background_downloader.dart';
// Import your isolate.dart
import 'services/objectbox_service.dart';
import 'services/playlist_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ObjectBox
  final objectBoxService = await ObjectBoxService.create();
  final playlistService = PlaylistService(objectBoxService);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Configure and start background_downloader
  await FileDownloader().configure(
    // This is a good place to set up global configurations
    // For example, requestTimeout, useCacheDir, localize, etc.
    // See CONFIG.md in the background_downloader package for more options.
    // Example:
    // globalConfig: [(Config.requestTimeout, const Duration(seconds: 100))],
    // androidConfig: [(Config.useCacheDir, Config.whenAble)],
    // iOSConfig: [(Config.localize, {'Cancel': 'StopIt'})],
  );

  // Register the background download callback
  FileDownloader().registerCallbacks(
    taskNotificationTapCallback: myNotificationTapCallback,
    // You can also register other callbacks here, e.g., for progress updates
    // or when a task completes.
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

  // Start the FileDownloader
  await FileDownloader().start();

  runApp(MyApp(playlistService: playlistService));
}

/// Process the user tapping on a notification by printing a message
@pragma('vm:entry-point')
void myNotificationTapCallback(Task task, NotificationType notificationType) {
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
