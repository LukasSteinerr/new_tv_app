import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'add_playlist_screen.dart';

class SettingsScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;
  final Function(double scrollOffset)? onScrollUpdate; // Add callback

  const SettingsScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
    this.onScrollUpdate, // Add callback parameter
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  late ScrollController _scrollController; // Add ScrollController

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Initialize ScrollController
    _scrollController.addListener(_notifyScrollUpdate); // Add listener
  }

  @override
  void dispose() {
    _scrollController.removeListener(_notifyScrollUpdate); // Remove listener
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  void _notifyScrollUpdate() {
    if (widget.onScrollUpdate != null) {
      widget.onScrollUpdate!(_scrollController.offset); // Call the callback
    }
  }

  Future<void> _refreshPlaylist() async {
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

    // Show a loading dialog that can't be dismissed by tapping outside
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevent back button from closing dialog
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
      // Run the heavy operation in the background
      await _performRefreshInBackground();

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

  Future<void> _performRefreshInBackground() async {
    // Use a microtask to ensure the dialog shows before starting heavy work
    await Future.microtask(() {});

    // Add small delays between major operations to allow UI updates
    await widget.playlistService.refreshPlaylist(widget.playlist);

    // Give a brief pause before returning to allow final UI updates
    await Future.delayed(const Duration(milliseconds: 100));
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
      // AppBar is removed from here and will be in the parent XtreamPlaylistScreen
      body: ListView(
        // Keep ListView for content
        controller: _scrollController, // Add the ScrollController
        padding: const EdgeInsets.only(
          top: kToolbarHeight + 24, // Add back top padding
        ),
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
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Refresh Tips'),
            subtitle: const Text(
              'If refresh takes too long:\n'
              '• Make sure your internet connection is stable\n'
              '• Large playlists may take 5-10 minutes\n'
              '• The app may appear frozen but is working',
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('About'),
            subtitle: Text('IPTV Player App\nVersion 1.0.0'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
