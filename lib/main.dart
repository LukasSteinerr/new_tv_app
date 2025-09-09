import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart'; // Import logging
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:force_update_helper/force_update_helper.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:developer';
import 'package:url_launcher/url_launcher.dart';
import 'router/app_router.dart';
import 'services/analytics_service.dart';
import 'services/objectbox_service.dart';
import 'services/playlist_service.dart';
import 'screens/home_screen.dart';
import 'package:background_downloader/background_downloader.dart';

import 'firebase_options.dart';

final _log = Logger('MainApp'); // Add logger

Future<void> _configureSDK() async {
  await Purchases.setLogLevel(LogLevel.debug);
  PurchasesConfiguration? configuration;

  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration("goog_NclmcljeFjGNTzmWMnzoweYTthP");
  } else if (Platform.isIOS) {
    configuration = PurchasesConfiguration("API_KEY");
  }

  if (configuration != null) {
    await Purchases.configure(configuration);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureSDK();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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

  final analyticsService = AnalyticsService();
  final appRouter = AppRouter(
    playlistService: playlistService,
    analyticsService: analyticsService,
  );

  runApp(MyApp(appRouter: appRouter));
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
  final AppRouter appRouter;

  const MyApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IPTV Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      routerConfig: appRouter.router,
      builder: (context, child) {
        return ForceUpdateWidget(
          navigatorKey: appRouter.router.routerDelegate.navigatorKey,
          forceUpdateClient: ForceUpdateClient(
            fetchRequiredVersion: () async {
              final remoteConfig = FirebaseRemoteConfig.instance;
              await remoteConfig.fetchAndActivate();
              return remoteConfig.getString('required_version');
            },
            // TODO: Replace with your actual iOS App Store ID. This is required for the force update to work on iOS.
            iosAppStoreId: '',
          ),
          allowCancel: false,
          showForceUpdateAlert:
              (context, allowCancel) => showDialog(
                context: context,
                barrierDismissible: allowCancel,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Update Required'),
                      content: const Text('Please update the app to continue.'),
                      actions: [
                        if (allowCancel)
                          TextButton(
                            child: const Text('Later'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        TextButton(
                          child: const Text('Update Now'),
                          onPressed: () {
                            // The package will handle opening the store.
                          },
                        ),
                      ],
                    ),
              ),
          showStoreListing: (storeUrl) async {
            if (await canLaunchUrl(storeUrl)) {
              await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
            } else {
              log('Cannot launch URL: $storeUrl');
            }
          },
          onException: (e, st) {
            log('ForceUpdateWidget error: $e', stackTrace: st);
          },
          child: child!,
        );
      },
    );
  }
}
