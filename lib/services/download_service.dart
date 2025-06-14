import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:logging/logging.dart';
import '../models/movie.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  final StreamController<Map<String, dynamic>> _downloadProgressController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get downloadProgressStream =>
      _downloadProgressController.stream;

  final Map<String, Movie> _tasks = {};
  final _log = Logger('DownloadService'); // Add logger

  DownloadService._internal() {
    _log.info('DownloadService initialized'); // Log initialization
    FileDownloader()
        .registerCallbacks(
          taskNotificationTapCallback: myNotificationTapCallback,
        )
        .configureNotificationForGroup(
          FileDownloader.defaultGroup,
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
        );

    FileDownloader().updates.listen((update) {
      _log.info(
        'Download update: ${update.runtimeType} for task ${update.task.taskId}',
      ); // Log all updates
      if (update is TaskStatusUpdate) {
        final movie = _tasks[update.task.taskId];
        if (movie != null) {
          _log.info(
            'Task status update for ${movie.name}: ${update.status}',
          ); // Log status updates
          _downloadProgressController.add({
            'id': movie.id,
            'name': movie.name,
            'progress': 0.0,
            'status': update.status.toString(),
          });
        }
      } else if (update is TaskProgressUpdate) {
        final movie = _tasks[update.task.taskId];
        if (movie != null) {
          _log.info(
            'Task progress update for ${movie.name}: ${update.progress}',
          ); // Log progress updates
          _downloadProgressController.add({
            'id': movie.id,
            'name': movie.name,
            'progress': update.progress,
            'status': 'Downloading',
          });
        }
      }
    });
    _log.info('FileDownloader started'); // Log FileDownloader start
  }

  void myNotificationTapCallback(Task task, NotificationType notificationType) {
    _log.info(
      'Notification tapped for taskId ${task.taskId}, type: $notificationType',
    ); // Log notification taps
    // Handle notification tap
  }

  Future<void> startDownload(Movie movie) async {
    _log.info(
      'Attempting to start download for movie: ${movie.name}',
    ); // Log download attempt
    final task = DownloadTask(
      url: movie.streamUrl,
      filename: '${movie.name}.mp4',
      directory: 'movies',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      allowPause: true,
      displayName: movie.name,
    );
    await FileDownloader().enqueue(task);
    _tasks[task.taskId] = movie;
    _log.info(
      'Download task enqueued for ${movie.name} with taskId: ${task.taskId}',
    ); // Log task enqueued
  }

  void dispose() {
    _downloadProgressController.close();
    _log.info('DownloadService disposed'); // Log disposal
  }
}
