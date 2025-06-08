import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: _downloadingMovies.length,
        itemBuilder: (context, index) {
          final movie = _downloadingMovies[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: Colors.grey[900],
              child: ListTile(
                leading: const Icon(Icons.movie, color: Colors.white),
                title: Text(
                  movie['name'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: movie['progress'],
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(movie['progress'] * 100).toInt()}% - ${movie['status']}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    movie['status'] == 'Downloading'
                        ? Icons.pause_circle_filled
                        : movie['status'] == 'Paused'
                        ? Icons.play_circle_filled
                        : Icons.check_circle,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // TODO: Implement pause/resume/delete functionality
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
