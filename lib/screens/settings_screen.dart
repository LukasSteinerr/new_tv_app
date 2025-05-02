import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'add_playlist_screen.dart';

class SettingsScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const SettingsScreen({
    Key? key,
    required this.playlistService,
    required this.playlist,
  }) : super(key: key);

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
        builder: (context) => AddPlaylistScreen(
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
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
          );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
