import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'add_playlist_screen.dart';

class SettingsScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const SettingsScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _refreshPlaylist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.playlistService.refreshPlaylist(widget.playlist);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist refreshed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing playlist: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editPlaylist() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddPlaylistScreen(
              playlistService: widget.playlistService,
              playlist: widget.playlist,
            ),
      ),
    );

    if (result == true) {
      // Playlist was updated, refresh the UI
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      // Remove the standard app bar
      extendBodyBehindAppBar: true, // Allow content to go behind app bar
      body: Stack(
        children: [
          // Main content
          ListView(
            padding: const EdgeInsets.only(
              top: 70,
            ), // Add padding for the app bar
            children: [
              ListTile(
                title: const Text('Playlist Information'),
                subtitle: Text(widget.playlist.name),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Playlist'),
                onTap: _editPlaylist,
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh Playlist'),
                subtitle: Text(
                  'Last updated: ${_formatDate(widget.playlist.lastUpdated)}',
                ),
                onTap: _refreshPlaylist,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Playlist Details'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${widget.playlist.typeName}'),
                    Text('URL: ${widget.playlist.url}'),
                    if (widget.playlist.username != null)
                      Text('Username: ${widget.playlist.username}'),
                  ],
                ),
              ),
              const Divider(),
              const ListTile(
                title: Text('About'),
                subtitle: Text('IPTV Player App\nVersion 1.0.0'),
              ),
            ],
          ),

          // Custom app bar with blur effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Back button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          // Title - Show playlist name
                          Text(
                            'Settings',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
