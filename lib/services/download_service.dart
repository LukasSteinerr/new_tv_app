import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import '../models/movie.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  final StreamController<Map<String, dynamic>> _downloadProgressController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get downloadProgressStream =>
      _downloadProgressController.stream;

  final Map<String, Movie> _tasks = {};

  DownloadService._internal() {
    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        final movie = _tasks[update.task.taskId];
        if (movie != null) {
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
          _downloadProgressController.add({
            'id': movie.id,
            'name': movie.name,
            'progress': update.progress,
            'status': 'Downloading',
          });
        }
      }
    });
  }

  Future<void> startDownload(Movie movie) async {
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
  }

  void dispose() {
    _downloadProgressController.close();
  }
}
