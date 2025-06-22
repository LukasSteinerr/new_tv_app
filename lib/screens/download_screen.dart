import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';
import '../services/download_service.dart';
import 'dart:async';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final DownloadService _downloadService = DownloadService();
  final List<Map<String, dynamic>> _downloadingMovies = [];
  StreamSubscription? _downloadProgressSubscription;

  @override
  void initState() {
    super.initState();
    _loadExistingDownloads();
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
    super.dispose();
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

  Future<void> _cancelDownload(String contentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Cancel Download',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to cancel this download?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await _downloadService.cancelDownload(contentId);
      if (success) {
        setState(() {
          _downloadingMovies.removeWhere((movie) => movie['id'] == contentId);
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel download'),
            backgroundColor: Colors.red,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body:
          _downloadingMovies.isEmpty
              ? const Center(
                child: Text(
                  'No downloads yet',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _downloadingMovies.length,
                itemBuilder: (context, index) {
                  final movie = _downloadingMovies[index];
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
                                const Icon(Icons.movie, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                // Pause button
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

                                // Cancel button
                                ElevatedButton.icon(
                                  onPressed:
                                      (status != TaskStatus.complete &&
                                              status != TaskStatus.failed &&
                                              status != TaskStatus.canceled)
                                          ? () => _cancelDownload(contentId)
                                          : null,
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Cancel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
