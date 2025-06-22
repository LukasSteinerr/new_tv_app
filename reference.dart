import 'dart:async';
import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';

class MkvDownloaderScreen extends StatefulWidget {
  const MkvDownloaderScreen({super.key});

  @override
  State<MkvDownloaderScreen> createState() => _MkvDownloaderScreenState();
}

class _MkvDownloaderScreenState extends State<MkvDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  double _progress = 0.0;
  TaskStatus? _status;
  late DownloadTask _task;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startDownload() async {
    final url = _urlController.text;
    if (url.isEmpty || !url.endsWith('.mkv')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid .mkv file URL')),
      );
      return;
    }

    final filename = url.split('/').last;
    _task = DownloadTask(url: url, filename: filename, allowPause: true);

    await FileDownloader().download(
      _task,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }
      },
      onStatus: (status) {
        if (mounted) {
          setState(() {
            _status = status;
          });
        }
      },
    );
  }

  Future<void> _pauseDownload() async {
    final success = await FileDownloader().pause(_task);
    if (!success) {
      debugPrint("Could not pause task.");
    }
  }

  Future<void> _resumeDownload() async {
    final success = await FileDownloader().resume(_task);
    if (!success) {
      debugPrint("Could not resume task.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MKV Downloader')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'MKV File URL',
                hintText: 'https://example.com/video.mkv',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  (_status == TaskStatus.running ||
                          _status == TaskStatus.enqueued ||
                          _status == TaskStatus.paused)
                      ? null
                      : _startDownload,
              child: const Text('Download MKV'),
            ),
            const SizedBox(height: 20),
            Visibility(
              visible: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed:
                        (_status == TaskStatus.running ||
                                _status == TaskStatus.enqueued)
                            ? _pauseDownload
                            : null,
                    child: const Text('Pause'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _status == TaskStatus.paused ? _resumeDownload : null,
                    child: const Text('Resume'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_status != null) ...[
              Text('Status: ${_status.toString().split('.').last}'),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _progress >= 0 ? _progress : null),
              const SizedBox(height: 5),
              Text(_progressText),
            ],
          ],
        ),
      ),
    );
  }

  String get _progressText {
    if (_status == TaskStatus.paused) {
      return 'Paused';
    }
    if (_progress <= 0) {
      return '';
    }
    if (_progress >= 1) {
      return 'Completed';
    }
    return '${(_progress * 100).toStringAsFixed(0)}%';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
