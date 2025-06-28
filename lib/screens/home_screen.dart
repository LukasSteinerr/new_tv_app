import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'add_playlist_screen.dart';
// import 'download_screen.dart'; // Removed import for DownloadScreen
import 'playlist_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final PlaylistService playlistService;

  const HomeScreen({super.key, required this.playlistService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final playlists = await widget.playlistService.getAllPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Error loading playlists: $e',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _refreshPlaylist(Playlist playlist) async {
    // Show a confirmation dialog before starting the refresh
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Refresh'),
          content: const Text(
            'Are you sure you want to refresh this playlist?\n'
            'This can take several minutes and cannot be stopped.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Refresh'),
            ),
          ],
        );
      },
    );

    // If the user did not confirm, do nothing
    if (confirmed != true) {
      return;
    }

    // Show a loading dialog that can't be dismissed
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Refreshing Playlist'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'This may take a few minutes...\nFetching channels, movies, TV series, and EPG data.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please wait and do not close the app.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Use a microtask to allow the dialog to render before heavy work
      await Future.microtask(() async {
        await widget.playlistService.refreshPlaylist(playlist);
        await _loadPlaylists();
      });

      if (mounted) {
        // Close the loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, s) {
      print('Error refreshing playlist: $e');
      print('Stack trace: $s');
      if (mounted) {
        // Close the loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing playlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Playlist'),
            content: Text(
              'Are you sure you want to delete "${playlist.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await widget.playlistService.deletePlaylist(playlist.id);
        await _loadPlaylists();

        // Show success message with green checkmark
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    'Playlist deleted successfully',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Error deleting playlist: $e',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IPTV Playlists'),
        actions: [
          // The download button has been removed from here.
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: Colors.white,
                  size: 50,
                ),
              )
              : _playlists.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No playlists added yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await context.push('/add-playlist');

                        if (result == true) {
                          await _loadPlaylists();
                        }
                      },
                      child: const Text('Add Playlist'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    title: Text(playlist.name),
                    subtitle: Text(
                      'Type: ${playlist.typeName} • Last updated: ${_formatDate(playlist.lastUpdated)}',
                    ),
                    leading: Icon(
                      playlist.isM3u ? Icons.playlist_play : Icons.cloud,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _refreshPlaylist(playlist),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deletePlaylist(playlist),
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/playlist-detail', extra: playlist);
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/add-playlist');
          if (result == true) {
            await _loadPlaylists();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
