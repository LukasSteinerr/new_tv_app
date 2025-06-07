import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../isolate.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final log = Logger('ExampleApp');
  final buttonTexts = ['Download', 'Cancel', 'Pause', 'Resume', 'Reset'];
  final _urlController = TextEditingController();

  ButtonState buttonState = ButtonState.download;
  bool downloadWithError = false;
  TaskStatus? downloadTaskStatus;
  DownloadTask? backgroundDownloadTask;
  static final StreamController<TaskUpdate> _updatesController =
      StreamController.broadcast();
  static StreamSubscription<TaskUpdate>? _downloaderSubscription;
  StreamSubscription<TaskUpdate>? _updateSubscription;

  bool loadAndOpenInProgress = false;
  bool loadABunchInProgress = false;
  bool loadBackgroundInProgress = false;
  String? loadBackgroundResult;

  @override
  void initState() {
    super.initState();
    log.info('initState');
    // By default the downloader uses a modified version of the Localstore package
    // to persistently store data. You can provide an alternative persistent
    // storage backing that implements the [PersistentStorage] interface. You
    // must initialize the FileDownloader by passing that alternative storage
    // object on the first call to FileDownloader.
    // For example, add a dependency for background_downloader_sql to
    // pubspec.yaml which adds [SqlitePersistentStorage].
    // To try that SQLite version, uncomment the following line, which
    // will initialize the downloader with the SQLite storage solution.
    // FileDownloader(persistentStorage: SqlitePersistentStorage());

    // optional: configure the downloader with platform specific settings,
    // see CONFIG.md - some examples shown here
    FileDownloader()
        .configure(
          globalConfig: [(Config.requestTimeout, const Duration(seconds: 100))],
          androidConfig: [(Config.useCacheDir, Config.whenAble)],
          iOSConfig: [
            (Config.localize, {'Cancel': 'StopIt'}),
          ],
        )
        .then((result) => debugPrint('Configuration result = $result'));

    // Registering a callback and configure notifications
    FileDownloader()
        .registerCallbacks(
          taskNotificationTapCallback: myNotificationTapCallback,
        )
        .configureNotificationForGroup(
          FileDownloader.defaultGroup,
          // For the main download button
          // which uses 'enqueue' and a default group
          running: const TaskNotification(
            'Download {filename}',
            'File: {filename} - {progress} - speed {networkSpeed} and {timeRemaining} remaining',
          ),
          complete: const TaskNotification(
            '{displayName} download {filename}',
            'Download complete',
          ),
          error: const TaskNotification(
            'Download {filename}',
            'Download failed',
          ),
          paused: const TaskNotification(
            'Download {filename}',
            'Paused with metadata {metadata}',
          ),
          canceled: const TaskNotification('Download {filename}', 'Canceled'),
          progressBar: true,
        )
        .configureNotificationForGroup(
          'bunch',
          running: const TaskNotification(
            '{numFinished} out of {numTotal}',
            'Progress = {progress}',
          ),
          complete: const TaskNotification("Done!", "Loaded {numTotal} files"),
          error: const TaskNotification(
            'Error',
            '{numFailed}/{numTotal} failed',
          ),
          progressBar: false,
          groupNotificationId: 'notGroup',
        )
        .configureNotification(
          // for the 'Download & Open' dog picture
          // which uses 'download' which is not the .defaultGroup
          // but the .await group so won't use the above config
          complete: const TaskNotification(
            'Download {filename}',
            'Download complete',
          ),
          tapOpensFile: true,
        ); // dog can also open directly from tap

    // Listen to updates and process
    _downloaderSubscription ??= FileDownloader().updates.listen((update) {
      _updatesController.add(update);
    });

    _updateSubscription = _updatesController.stream.listen((update) {
      log.info('Received update: $update');
      switch (update) {
        case TaskStatusUpdate():
          if (update.task == backgroundDownloadTask) {
            if (mounted) {
              setState(() {
                buttonState = switch (update.status) {
                  TaskStatus.running ||
                  TaskStatus.enqueued => ButtonState.pause,
                  TaskStatus.paused => ButtonState.resume,
                  _ => ButtonState.reset,
                };
                downloadTaskStatus = update.status;
              });
            }
          }

        case TaskProgressUpdate():
        // Not used in this simplified version
      }
    });
    // Start the FileDownloader. Default start means database tracking and
    // proper handling of events that happened while the app was suspended,
    // and rescheduling of tasks that were killed by the user.
    // Start behavior can be configured with parameters
    FileDownloader().start();
  }

  @override
  void dispose() {
    log.info('dispose');
    _updateSubscription?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  /// Process the user tapping on a notification by printing a message
  void myNotificationTapCallback(Task task, NotificationType notificationType) {
    debugPrint(
      'Tapped notification $notificationType for taskId ${task.taskId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    log.info('build');
    return Scaffold(
      appBar: AppBar(title: const Text('background_downloader example app')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Enter URL to download',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: processButtonPress,
                  child: Text(buttonTexts[buttonState.index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Expanded(child: Text('File download status:')),
                    Text('${downloadTaskStatus ?? "undefined"}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Process center button press (initially 'Download' but the text changes
  /// based on state)
  Future<void> processButtonPress() async {
    switch (buttonState) {
      case ButtonState.download:
        // start download
        if (_urlController.text.isEmpty) {
          return;
        }
        await getPermission(PermissionType.notifications);
        backgroundDownloadTask = DownloadTask(
          url: _urlController.text,
          filename: _urlController.text.split('/').last,
          directory: 'downloads',
          baseDirectory: BaseDirectory.applicationDocuments,
          updates: Updates.statusAndProgress,
          retries: 3,
          allowPause: true,
          metaData: '<example metaData>',
          displayName: 'My display name',
        );
        await FileDownloader().enqueue(backgroundDownloadTask!);
        break;
      case ButtonState.cancel:
        // cancel download
        if (backgroundDownloadTask != null) {
          await FileDownloader().cancelTasksWithIds([
            backgroundDownloadTask!.taskId,
          ]);
        }
        break;
      case ButtonState.reset:
        downloadTaskStatus = null;
        buttonState = ButtonState.download;
        break;
      case ButtonState.pause:
        if (backgroundDownloadTask != null) {
          await FileDownloader().pause(backgroundDownloadTask!);
        }
        break;
      case ButtonState.resume:
        if (backgroundDownloadTask != null) {
          await FileDownloader().resume(backgroundDownloadTask!);
        }
        break;
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Process 'Load & Open' button
  ///
  /// Loads a JPG of a dog and launches viewer using [openFile]
  Future<void> processLoadAndOpen() async {
    if (!loadAndOpenInProgress) {
      await getPermission(PermissionType.notifications);
      var task = DownloadTask(
        url:
            'https://i2.wp.com/www.skiptomylou.org/wp-content/uploads/2019/06/dog-drawing.jpg',
        baseDirectory: BaseDirectory.applicationSupport,
        filename: 'dog.jpg',
      );
      setState(() {
        loadAndOpenInProgress = true;
      });
      await FileDownloader().download(task);
      await FileDownloader().openFile(task: task);
      if (Platform.isIOS) {
        // add to photos library and print path
        // If you need the path, ask full permissions beforehand by calling
        var auth = await FileDownloader().permissions.status(
          PermissionType.iosChangePhotoLibrary,
        );
        if (auth != PermissionStatus.granted) {
          auth = await FileDownloader().permissions.request(
            PermissionType.iosChangePhotoLibrary,
          );
        }
        if (auth == PermissionStatus.granted) {
          final identifier = await FileDownloader().moveToSharedStorage(
            task,
            SharedStorage.images,
          );
          if (identifier != null) {
            final path = await FileDownloader().pathInSharedStorage(
              identifier,
              SharedStorage.images,
            );
            debugPrint(
              'iOS path to dog picture in Photos Library = ${path ?? "permission denied"}',
            );
          } else {
            debugPrint(
              'Could not add file to Photos Library, likely because permission denied',
            );
          }
        } else {
          debugPrint('iOS Photo Library permission not granted');
        }
      }
      if (Platform.isAndroid) {
        // on Android we move, not add, so we first wat for the
        // openFile method to complete
        await Future.delayed(const Duration(seconds: 3));
        var auth = await FileDownloader().permissions.status(
          PermissionType.androidSharedStorage,
        );
        if (auth != PermissionStatus.granted) {
          auth = await FileDownloader().permissions.request(
            PermissionType.androidSharedStorage,
          );
        }
        if (auth == PermissionStatus.granted) {
          final path = await FileDownloader().moveToSharedStorage(
            task,
            SharedStorage.images,
          );
          debugPrint(
            'Android path to dog picture in .images = ${path ?? "permission denied"}',
          );
        } else {
          debugPrint('androidSharedStorage permission not granted');
        }
      }
      setState(() {
        loadAndOpenInProgress = false;
      });
    }
  }

  Future<void> processLoadABunch() async {
    if (!loadABunchInProgress) {
      setState(() {
        loadABunchInProgress = true;
      });
      await getPermission(PermissionType.notifications);
      for (var i = 0; i < 5; i++) {
        await FileDownloader().enqueue(
          DownloadTask(
            url:
                'https://storage.googleapis.com/approachcharts/test/5MB-test.ZIP',
            filename: 'File_${Random().nextInt(1000)}',
            group: 'bunch',
            updates: Updates.progress,
          ),
        ); // must provide progress updates!
        await Future.delayed(const Duration(milliseconds: 500));
      }
      setState(() {
        loadABunchInProgress = false;
      });
    }
  }

  Future<void> processLoadBackground() async {
    if (!loadBackgroundInProgress) {
      setState(() {
        loadBackgroundInProgress = true;
      });
      await getPermission(PermissionType.notifications);
      final result = await testBackgroundUsage();
      setState(() {
        loadBackgroundResult = result;
        loadBackgroundInProgress = false;
      });
    }
  }

  Future<void> processPickDirectory() async {
    final uri = await FileDownloader().uri.pickDirectory();
    if (uri == null) {
      log.warning('Could not get a URI');
      return;
    }
    log.fine('Uri = $uri');
    final task = UriDownloadTask(
      url:
          'https://i2.wp.com/www.skiptomylou.org/wp-content/uploads/2019/06/dog-drawing.jpg',
      directoryUri: uri,
      filename: '?',
    );
    final result = await FileDownloader().download(task);
    final resultTask = result.task as UriDownloadTask;
    log.info('Download to URI completed with taskStatus ${result.status}');
    log.info('Downloaded file is at ${resultTask.fileUri}');
    log.info('Downloaded file name is ${resultTask.filename}');
  }

  /// Attempt to get permissions if not already granted
  Future<void> getPermission(PermissionType permissionType) async {
    var status = await FileDownloader().permissions.status(permissionType);
    if (status != PermissionStatus.granted) {
      if (await FileDownloader().permissions.shouldShowRationale(
        permissionType,
      )) {
        debugPrint('Showing some rationale');
      }
      status = await FileDownloader().permissions.request(permissionType);
      debugPrint('Permission for $permissionType was $status');
    }
  }
}

/// Segmented button with WiFi requirement states
class RequireWiFiChoice extends StatefulWidget {
  const RequireWiFiChoice({super.key});

  @override
  State<RequireWiFiChoice> createState() => _RequireWiFiChoiceState();
}

class _RequireWiFiChoiceState extends State<RequireWiFiChoice> {
  RequireWiFi requireWiFi = RequireWiFi.asSetByTask;

  @override
  void initState() {
    super.initState();
    FileDownloader().getRequireWiFiSetting().then((value) {
      setState(() {
        requireWiFi = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RequireWiFi>(
      segments: const <ButtonSegment<RequireWiFi>>[
        ButtonSegment<RequireWiFi>(
          value: RequireWiFi.asSetByTask,
          label: Text('Task'),
        ),
        ButtonSegment<RequireWiFi>(
          value: RequireWiFi.forAllTasks,
          label: Text('All'),
        ),
        ButtonSegment<RequireWiFi>(
          value: RequireWiFi.forNoTasks,
          label: Text('None'),
        ),
      ],
      selected: <RequireWiFi>{requireWiFi},
      onSelectionChanged: (Set<RequireWiFi> newSelection) {
        setState(() {
          // By default there is only a single segment that can be
          // selected at one time, so its value is always the first
          // item in the selected set.
          requireWiFi = newSelection.first;
          unawaited(
            FileDownloader().requireWiFi(
              requireWiFi,
              rescheduleRunningTasks: true,
            ),
          );
        });
      },
    );
  }
}

enum ButtonState { download, cancel, pause, resume, reset }
