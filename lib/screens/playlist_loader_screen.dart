import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../models/playlist.dart';
import '../services/objectbox_service.dart';
import '../services/playlist_service.dart';

// Background function that runs in isolate
Future<void> _backgroundPreparation(dynamic input) async {
  await Future.delayed(const Duration(milliseconds: 5));
}

class PlaylistLoaderScreen extends StatefulWidget {
  final Playlist playlist;
  final PlaylistService playlistService;

  const PlaylistLoaderScreen({
    super.key,
    required this.playlist,
    required this.playlistService,
  });

  @override
  State<PlaylistLoaderScreen> createState() => _PlaylistLoaderScreenState();
}

class _PlaylistLoaderScreenState extends State<PlaylistLoaderScreen> {
  @override
  void initState() {
    super.initState();

    // Start initialization after the widget is built and animation is running
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startChunkedInitialization();
    });
  }

  Future<void> _startChunkedInitialization() async {
    try {
      // Chunk 1: Let animation establish rhythm
      await _yieldToUI(500);

      // Chunk 2: Background preparation
      await compute(_backgroundPreparation, null);
      await _yieldToUI(50);

      // Chunk 3: Pre-initialization work
      await _yieldToUI(50);

      // Chunk 4: Create ObjectBox service with yielding
      await _createObjectBoxWithYielding();

      // Chunk 5: Final navigation
      await _yieldToUI(50);

      if (mounted) {
        // Navigate to different screens based on playlist type
        if (widget.playlist.isM3u) {
          // M3U playlists go to playlist-detail screen
          context.pushReplacement('/playlist-detail', extra: widget.playlist);
        } else {
          // Xtream playlists go to playlist screen
          context.pushReplacement(
            '/playlist',
            extra: {
              'playlist': widget.playlist,
              'playlistService': widget.playlistService,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load playlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _createObjectBoxWithYielding() async {
    // Split the ObjectBox creation into smaller chunks with yielding
    for (int i = 0; i < 10; i++) {
      // Yield to UI thread before each attempt
      await _yieldToUI(20);

      if (i == 9) {
        // Actually create ObjectBox on the last iteration
        await ObjectBoxService.create();
      }
    }
  }

  Future<void> _yieldToUI(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
    // Also yield to scheduler to ensure frame rendering
    await SchedulerBinding.instance.endOfFrame;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4.0),
      ),
    );
  }
}
