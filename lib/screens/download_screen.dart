import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:go_router/go_router.dart';
import '../services/download_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/objectbox_service.dart';
import '../models/movie.dart';
import '../models/tv_episode.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen>
    with TickerProviderStateMixin {
  final DownloadService _downloadService = DownloadService();
  final List<Map<String, dynamic>> _downloadingMovies = [];
  StreamSubscription? _downloadProgressSubscription;
  late TabController _tabController;
  List<FileSystemEntity> _allFiles = [];
  ObjectBoxService? _objectBoxService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
    _loadExistingDownloads();
    _loadAllFiles();
    _downloadProgressSubscription = _downloadService.downloadProgressStream
        .listen((data) {
          setState(() {
            // Find the movie in the list and update its progress
            final index = _downloadingMovies.indexWhere(
              (movie) => movie['id'] == data['id'],
            );
            if (index != -1) {
              _downloadingMovies[index] = data;
            } else {
              _downloadingMovies.add(data);
            }
          });
        });
  }

  @override
  void dispose() {
    _downloadProgressSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _objectBoxService = await ObjectBoxService.create();
  }

  Future<void> _pauseDownload(String contentId) async {
    final success = await _downloadService.pauseDownload(contentId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pause download'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resumeDownload(String contentId) async {
    final success = await _downloadService.resumeDownload(contentId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resume download'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDownload(String contentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Delete Download',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this download record?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('No', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // First cancel the task (if it is still running) so we don't leave a dangling download
      await _downloadService.cancelDownload(contentId);

      // Locate the corresponding database record by matching the metaData (which we use to
      // store the contentId). We then delete the record using the *taskId* which is what
      // `deleteRecordWithId` expects.
      final records = await FileDownloader().database.allRecords();
      for (final record in records) {
        if (record.task.metaData == contentId) {
          await FileDownloader().database.deleteRecordWithId(
            record.task.taskId,
          );
          break;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download record deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadExistingDownloads();
      }
    }
  }

  Future<void> _deleteAllDownloads() async {
    final count = (await _downloadService.getAllDownloads()).length;
    if (count == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No download history to delete.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Delete All Downloads',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete all $count download records? This action cannot be undone.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('No', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final records = await FileDownloader().database.allRecords();
      final numDeleted = records.length;
      await FileDownloader().database.deleteAllRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$numDeleted download records deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadExistingDownloads();
      }
    }
  }

  Future<void> _loadExistingDownloads() async {
    final existingDownloads = await _downloadService.getAllDownloads();
    if (mounted) {
      setState(() {
        _downloadingMovies.clear();
        _downloadingMovies.addAll(existingDownloads);
      });
    }
  }

  Future<void> _loadAllFiles() async {
    final List<FileSystemEntity> files = [];
    final appDir = await getApplicationDocumentsDirectory();

    final moviesDir = Directory('${appDir.path}/movies');
    final episodesDir = Directory('${appDir.path}/episodes');

    if (moviesDir.existsSync()) {
      files.addAll(moviesDir.listSync());
    }
    if (episodesDir.existsSync()) {
      files.addAll(episodesDir.listSync());
    }

    setState(() {
      _allFiles = files;
    });
  }

  String _getStatusText(Map<String, dynamic> movie) {
    final status = movie['status'] as TaskStatus;
    final progress = movie['progress'] as double;

    switch (status) {
      case TaskStatus.enqueued:
        return 'Queued';
      case TaskStatus.running:
        return 'Downloading ${(progress * 100).toInt()}%';
      case TaskStatus.paused:
        return 'Paused ${(progress * 100).toInt()}%';
      case TaskStatus.complete:
        return 'Completed';
      case TaskStatus.failed:
        return 'Failed';
      case TaskStatus.canceled:
        return 'Canceled';
      case TaskStatus.notFound:
        return 'Not Found';
      case TaskStatus.waitingToRetry:
        return 'Retrying...';
      default:
        return movie['statusString'] ?? 'Unknown';
    }
  }

  Color _getProgressColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.complete:
        return Colors.green;
      case TaskStatus.failed:
      case TaskStatus.canceled:
        return Colors.red;
      case TaskStatus.paused:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  List<Map<String, dynamic>> _getMovieDownloads() {
    return _downloadingMovies.where((download) {
      final directory = download['directory'] as String?;
      print('Download: ${download['name']} - Directory: $directory'); // Debug
      return directory == 'movies';
    }).toList();
  }

  List<Map<String, dynamic>> _getTvShowDownloads() {
    return _downloadingMovies.where((download) {
      final directory = download['directory'] as String?;
      return directory == 'episodes';
    }).toList();
  }

  List<Map<String, dynamic>> _getUnknownDownloads() {
    return _downloadingMovies.where((download) {
      final directory = download['directory'] as String?;
      return directory == null ||
          (directory != 'movies' && directory != 'episodes');
    }).toList();
  }

  Widget _buildFileListItem(FileSystemEntity file) {
    return ListTile(
      leading: const Icon(Icons.movie, color: Colors.white),
      title: Text(
        file.path.split('/').last,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Delete File',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to permanently delete this file?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(false),
                      child: const Text(
                        'No',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pop(true),
                      child: const Text(
                        'Yes',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
          );

          if (confirmed == true) {
            try {
              file.deleteSync();
              _loadAllFiles();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File deleted successfully.'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting file: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildDownloadList(
    List<Map<String, dynamic>> downloads,
    IconData iconData,
  ) {
    if (downloads.isEmpty) {
      return const Center(
        child: Text(
          'No downloads yet',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final movie = downloads[index];
        final status = movie['status'] as TaskStatus;
        final progress = movie['progress'] as double;
        final contentId = movie['id'] as String;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            color: Colors.grey[900],
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie title and progress
                  Row(
                    children: [
                      Icon(iconData, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStatusText(movie),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress bar
                  LinearProgressIndicator(
                    value: progress >= 0 ? progress : null,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(status),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (status == TaskStatus.complete)
                        ElevatedButton.icon(
                          onPressed: () => _playVideo(movie),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Play'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),

                      // Pause button
                      if (status != TaskStatus.complete)
                        ElevatedButton.icon(
                          onPressed:
                              (status == TaskStatus.running ||
                                      status == TaskStatus.enqueued)
                                  ? () => _pauseDownload(contentId)
                                  : null,
                          icon: const Icon(Icons.pause, size: 18),
                          label: const Text('Pause'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[700],
                          ),
                        ),

                      // Resume button
                      if (status != TaskStatus.complete)
                        ElevatedButton.icon(
                          onPressed:
                              status == TaskStatus.paused
                                  ? () => _resumeDownload(contentId)
                                  : null,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Resume'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[700],
                          ),
                        ),

                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        tooltip: 'Delete this download',
                        onPressed: () => _deleteDownload(contentId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieDownloads = _getMovieDownloads();
    final tvShowDownloads = _getTvShowDownloads();
    final unknownDownloads = _getUnknownDownloads();

    print('Total downloads: ${_downloadingMovies.length}'); // Debug
    print('Movie downloads: ${movieDownloads.length}'); // Debug
    print('TV downloads: ${tvShowDownloads.length}'); // Debug
    print('Unknown downloads: ${unknownDownloads.length}'); // Debug

    // If we have unknown downloads (without directory info), show them in movies tab for now
    final combinedMovieDownloads = [...movieDownloads, ...unknownDownloads];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Downloads'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Movies (${combinedMovieDownloads.length})'),
            Tab(text: 'TV Shows (${tvShowDownloads.length})'),
            Tab(text: 'All Files (${_allFiles.length})'),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadList(combinedMovieDownloads, Icons.movie),
          _buildDownloadList(tvShowDownloads, Icons.tv),
          _buildAllFilesList(),
        ],
      ),
    );
  }

  Widget _buildAllFilesList() {
    if (_allFiles.isEmpty) {
      return const Center(
        child: Text(
          'No files found in storage.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ListView.builder(
      itemCount: _allFiles.length,
      itemBuilder: (context, index) {
        return _buildFileListItem(_allFiles[index]);
      },
    );
  }

  Future<void> _playVideo(Map<String, dynamic> downloadData) async {
    if (_objectBoxService == null) return;

    final contentId = int.tryParse(downloadData['id'] as String);
    if (contentId == null) return;

    final directory = downloadData['directory'] as String?;
    final name = downloadData['name'] as String;
    final appDir = await getApplicationDocumentsDirectory();
    final localPath = '${appDir.path}/$directory/$name.mp4';

    if (directory == 'movies') {
      final movie = _objectBoxService!.getMovieByDbId(contentId);
      if (movie != null) {
        context.push(
          '/video-player',
          extra: {'movie': movie, 'localPath': localPath},
        );
      }
    } else if (directory == 'episodes') {
      final episode = _objectBoxService!.getTvEpisodeByDbId(contentId);
      if (episode != null) {
        context.push(
          '/video-player',
          extra: {'episode': episode, 'localPath': localPath},
        );
      }
    }
  }
}
