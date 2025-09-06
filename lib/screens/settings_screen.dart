import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:go_router/go_router.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import '../services/download_service.dart';
import '../widgets/focusable_settings_item.dart';

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
  final bool _isLoading = false;
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
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
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
        context.pop();

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
        context.pop();

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
    final result = await context.push('/add-playlist', extra: widget.playlist);

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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: kToolbarHeight + 24),
        children: [
          _buildSectionHeader('Account'),
          FocusableSettingsItem(
            icon: Icons.edit,
            title: 'Edit Playlist',
            onTap: _editPlaylist,
          ),
          FocusableSettingsItem(
            icon: Icons.refresh,
            title: 'Refresh Playlist',
            subtitle:
                'Last updated: ${_formatDate(widget.playlist.lastUpdated)}',
            onTap: _refreshPlaylist,
          ),
          FocusableSettingsItem(
            icon: Icons.info_outline,
            title: 'Playlist Details',
            subtitle: '${widget.playlist.name} - ${widget.playlist.typeName}',
            onTap: () => _showPlaylistDetails(context),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Settings'),
          FocusableSettingsItem(
            icon: Icons.delete_sweep,
            title: 'Delete Download History',
            subtitle: 'Remove all download records',
            onTap: _deleteAllDownloads,
          ),
          FocusableSettingsItem(
            icon: Icons.help_outline,
            title: 'Refresh Tips',
            onTap: () => _showRefreshTips(context),
          ),
          FocusableSettingsItem(
            icon: Icons.info,
            title: 'About',
            subtitle: 'IPTV Player App - Version 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 20.0,
        bottom: 10.0,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPlaylistDetails(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Playlist Details',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${widget.playlist.name}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${widget.playlist.typeName}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'URL: ${widget.playlist.url}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (widget.playlist.username != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Username: ${widget.playlist.username}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showRefreshTips(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Refresh Tips',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              '• Make sure your internet connection is stable.\n'
              '• Large playlists may take 5-10 minutes.\n'
              '• The app may appear frozen but is working.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Got it',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('About', style: TextStyle(color: Colors.white)),
            content: const Text(
              'IPTV Player App\nVersion 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteAllDownloads() async {
    final downloadService = DownloadService();
    final count = (await downloadService.getAllDownloads()).length;
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
      }
    }
  }
}
