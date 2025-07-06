import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/movie.dart';
import '../models/tv_episode.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  final StreamController<Map<String, dynamic>> _downloadProgressController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get downloadProgressStream =>
      _downloadProgressController.stream;

  final _log = Logger('DownloadService'); // Add logger

  // Store active download tasks by content ID
  final Map<String, DownloadTask> _activeTasks = {};

  DownloadService._internal() {
    _log.info('DownloadService initialized'); // Log initialization
    _initializeActiveTasks(); // Initialize active tasks from existing downloads

    FileDownloader().registerCallbacks(
      taskNotificationTapCallback: myNotificationTapCallback,
    );

    FileDownloader().updates.listen((update) async {
      _log.info(
        'Download update: ${update.runtimeType} for task ${update.task.taskId}',
      ); // Log all updates

      if (update.task.metaData.isEmpty) {
        _log.info(
          'Ignoring update for task with no metaData: ${update.task.taskId}',
        );
        return;
      }
      final movieId = update.task.metaData;
      final movieName = update.task.displayName;

      if (update is TaskStatusUpdate) {
        final record = await FileDownloader().database.recordForId(
          update.task.taskId,
        );
        final progress = record?.progress ?? 0.0;
        _log.info(
          'Task status update for $movieName: ${update.status}',
        ); // Log status updates

        // Remove task from active tasks if completed or failed
        if (update.status == TaskStatus.complete ||
            update.status == TaskStatus.failed ||
            update.status == TaskStatus.canceled) {
          _activeTasks.remove(movieId);
        }

        // Don't send canceled downloads to UI - they should be removed immediately
        if (update.status != TaskStatus.canceled) {
          _downloadProgressController.add({
            'id': movieId,
            'name': movieName,
            'progress': progress,
            'status': update.status,
            'statusString': update.status.toString().split('.').last,
            'directory': update.task.directory, // Add directory info
          });
        }
      } else if (update is TaskProgressUpdate) {
        _log.info(
          'Task progress update for $movieName: ${update.progress}',
        ); // Log progress updates
        _downloadProgressController.add({
          'id': movieId,
          'name': movieName,
          'progress': update.progress,
          'status': TaskStatus.running,
          'statusString': 'running',
          'directory': update.task.directory, // Add directory info
        });
      }
    });
    _log.info('FileDownloader started'); // Log FileDownloader start
  }

  Future<void> _initializeActiveTasks() async {
    try {
      // Resume from background to get latest state
      await FileDownloader().resumeFromBackground();

      // Get all active tasks and populate our _activeTasks map
      final allTasks = await FileDownloader().allTasks(allGroups: true);

      for (final task in allTasks) {
        if (task.metaData.isNotEmpty && task is DownloadTask) {
          _activeTasks[task.metaData] = task;
          _log.info('Restored active task for content ID: ${task.metaData}');
        }
      }

      _log.info('Initialized ${_activeTasks.length} active tasks');
    } catch (e) {
      _log.severe('Error initializing active tasks: $e');
    }
  }

  void myNotificationTapCallback(Task task, NotificationType notificationType) {
    _log.info(
      'Notification tapped for taskId ${task.taskId}, type: $notificationType',
    ); // Log notification taps
    // Handle notification tap
  }

  Future<void> startDownload(dynamic content) async {
    // Request notification permission before starting download
    var status = await Permission.notification.status;
    if (status.isDenied) {
      // Here, you can request the permission.
      if (await Permission.notification.request().isGranted) {
        // Permission is granted, you can now proceed with the download.
        _log.info('Notification permission granted.');
      } else {
        // Permission is denied.
        _log.warning('Notification permission denied.');
      }
    } else if (status.isPermanentlyDenied) {
      // The user has permanently denied the permission.
      // You can open the app settings to allow the user to enable it manually.
      _log.warning('Notification permission permanently denied.');
      openAppSettings();
    }

    if (content is Movie) {
      _log.info(
        'Attempting to start download for movie: ${content.name}',
      ); // Log download attempt
      final task = DownloadTask(
        url: content.streamUrl,
        filename: '${content.name}.mp4',
        directory: 'movies',
        baseDirectory: BaseDirectory.applicationDocuments,
        updates: Updates.statusAndProgress,
        allowPause: true,
        displayName: content.name,
        metaData: content.id.toString(),
      );

      // Store task reference
      _activeTasks[content.id.toString()] = task;

      await FileDownloader().enqueue(task);
      _log.info(
        'Download task enqueued for ${content.name} with taskId: ${task.taskId}',
      ); // Log task enqueued
    } else if (content is TvEpisode) {
      _log.info(
        'Attempting to start download for TV episode: ${content.title}',
      );
      final task = DownloadTask(
        url: content.streamUrl,
        filename: '${content.title}.mp4',
        directory: 'episodes',
        baseDirectory: BaseDirectory.applicationDocuments,
        updates: Updates.statusAndProgress,
        allowPause: true,
        displayName: content.title,
        metaData: content.id.toString(),
      );

      // Store task reference
      _activeTasks[content.id.toString()] = task;

      await FileDownloader().enqueue(task);
      _log.info(
        'Download task enqueued for ${content.title} with taskId: ${task.taskId}',
      );
    }
  }

  Future<bool> pauseDownload(String contentId) async {
    final task = _activeTasks[contentId];
    if (task == null) {
      _log.warning('No active task found for content ID: $contentId');
      // Try to resync and find the task
      await _resyncActiveTasks();
      final retryTask = _activeTasks[contentId];
      if (retryTask == null) {
        _log.warning(
          'Task still not found after resync for content ID: $contentId',
        );
        return false;
      }
      return await FileDownloader().pause(retryTask);
    }

    final success = await FileDownloader().pause(task);
    if (success) {
      _log.info('Successfully paused download for content ID: $contentId');
    } else {
      _log.warning('Failed to pause download for content ID: $contentId');
    }
    return success;
  }

  Future<bool> resumeDownload(String contentId) async {
    final task = _activeTasks[contentId];
    if (task == null) {
      _log.warning('No active task found for content ID: $contentId');
      // Try to resync and find the task
      await _resyncActiveTasks();
      final retryTask = _activeTasks[contentId];
      if (retryTask == null) {
        _log.warning(
          'Task still not found after resync for content ID: $contentId',
        );
        return false;
      }
      return await FileDownloader().resume(retryTask);
    }

    final success = await FileDownloader().resume(task);
    if (success) {
      _log.info('Successfully resumed download for content ID: $contentId');
    } else {
      _log.warning('Failed to resume download for content ID: $contentId');
    }
    return success;
  }

  Future<bool> cancelDownload(String contentId) async {
    final task = _activeTasks[contentId];
    if (task == null) {
      _log.warning('No active task found for content ID: $contentId');
      // Try to resync and find the task
      await _resyncActiveTasks();
      final retryTask = _activeTasks[contentId];
      if (retryTask == null) {
        _log.warning(
          'Task still not found after resync for content ID: $contentId',
        );
        return false;
      }
      final success = await FileDownloader().cancel(retryTask);
      if (success) {
        _activeTasks.remove(contentId);
        _log.info('Successfully canceled download for content ID: $contentId');
      }
      return success;
    }

    final success = await FileDownloader().cancel(task);
    if (success) {
      _activeTasks.remove(contentId);
      _log.info('Successfully canceled download for content ID: $contentId');
    } else {
      _log.warning('Failed to cancel download for content ID: $contentId');
    }
    return success;
  }

  Future<void> _resyncActiveTasks() async {
    try {
      _log.info('Resyncing active tasks...');
      await FileDownloader().resumeFromBackground();

      // Get all active tasks and update our _activeTasks map
      final allTasks = await FileDownloader().allTasks(allGroups: true);

      // Clear and rebuild the map
      _activeTasks.clear();

      for (final task in allTasks) {
        if (task.metaData.isNotEmpty && task is DownloadTask) {
          _activeTasks[task.metaData] = task;
          _log.info('Resynced active task for content ID: ${task.metaData}');
        }
      }

      _log.info('Resynced ${_activeTasks.length} active tasks');
    } catch (e) {
      _log.severe('Error resyncing active tasks: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    final List<Map<String, dynamic>> allDownloads = [];

    try {
      // Get all records from the database
      final records = await FileDownloader().database.allRecords();

      for (final record in records) {
        if (record.task.metaData.isNotEmpty) {
          // Skip canceled downloads - they shouldn't appear in UI
          if (record.status == TaskStatus.canceled) {
            continue;
          }

          final downloadData = {
            'id': record.task.metaData,
            'name': record.task.displayName,
            'progress': record.progress,
            'status': record.status,
            'statusString': record.status.toString().split('.').last,
            'directory': record.task.directory, // Add directory info
          };
          allDownloads.add(downloadData);

          // Also update the active tasks map if the download is still active
          if (record.status != TaskStatus.complete &&
              record.status != TaskStatus.failed &&
              record.status != TaskStatus.canceled) {
            _activeTasks[record.task.metaData] = record.task as DownloadTask;
          }
        }
      }

      _log.info(
        'Retrieved ${allDownloads.length} downloads from database (excluding canceled)',
      );
    } catch (e) {
      _log.severe('Error retrieving downloads: $e');
    }

    return allDownloads;
  }

  void dispose() {
    _downloadProgressController.close();
    _activeTasks.clear();
    _log.info('DownloadService disposed'); // Log disposal
  }
}
