import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:logging/logging.dart';
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

  DownloadService._internal() {
    _log.info('DownloadService initialized'); // Log initialization
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
        _downloadProgressController.add({
          'id': movieId,
          'name': movieName,
          'progress': progress,
          'status': update.status.toString(),
        });
      } else if (update is TaskProgressUpdate) {
        _log.info(
          'Task progress update for $movieName: ${update.progress}',
        ); // Log progress updates
        _downloadProgressController.add({
          'id': movieId,
          'name': movieName,
          'progress': update.progress,
          'status': 'Downloading',
        });
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

  Future<void> startDownload(dynamic content) async {
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
      await FileDownloader().enqueue(task);
      _log.info(
        'Download task enqueued for ${content.title} with taskId: ${task.taskId}',
      );
    }
  }

  void dispose() {
    _downloadProgressController.close();
    _log.info('DownloadService disposed'); // Log disposal
  }
}
