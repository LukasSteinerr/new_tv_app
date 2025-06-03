import 'package:flutter/material.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        backgroundColor: Colors.black87,
      ),
      body: const Center(
        child: Text(
          'Download Screen Content Here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
