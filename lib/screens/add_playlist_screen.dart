import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:ui'; // For ImageFilter
import '../models/playlist.dart';
import '../services/analytics_service.dart';
import '../services/playlist_service.dart';

class AddPlaylistScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final AnalyticsService analyticsService;
  final Playlist? playlist; // For editing existing playlist

  const AddPlaylistScreen({
    super.key,
    required this.playlistService,
    required this.analyticsService,
    this.playlist,
  });

  @override
  State<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends State<AddPlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  int _playlistTypeInt = PlaylistTypeConstants.m3u;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If editing existing playlist, populate the form
    if (widget.playlist != null) {
      _nameController.text = widget.playlist!.name;
      _urlController.text = widget.playlist!.url;
      _usernameController.text = widget.playlist!.username ?? '';
      _passwordController.text = widget.playlist!.password ?? '';
      _playlistTypeInt = widget.playlist!.typeInt;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _savePlaylist() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      widget.analyticsService.logPlaylistAddAttempt();

      try {
        Playlist playlist;

        if (_playlistTypeInt == PlaylistTypeConstants.m3u) {
          playlist = Playlist.m3u(
            name: _nameController.text,
            url: _urlController.text,
          );
        } else {
          playlist = Playlist.xtream(
            name: _nameController.text,
            url: _urlController.text,
            username: _usernameController.text,
            password: _passwordController.text,
          );
        }

        if (widget.playlist != null) {
          // Update existing playlist
          playlist.id = widget.playlist!.id;
        }

        await widget.playlistService.fetchAndSavePlaylistData(playlist);
        widget.analyticsService.logPlaylistAddSuccess();
        if (mounted) {
          // Show success message with green checkmark
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text(
                    widget.playlist == null
                        ? 'Playlist added successfully'
                        : 'Playlist updated successfully',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 2),
            ),
          );

          context.pop(true);
        }
      } catch (e) {
        widget.analyticsService.logPlaylistAddFailed(reason: e.toString());
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
                      'Error saving playlist: $e',
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
      // Remove the standard app bar
      extendBodyBehindAppBar: true, // Allow content to go behind app bar
      body: Stack(
        children: [
          // Main content
          _isLoading
              ? Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: Colors.white,
                  size: 50,
                ),
              )
              : SingleChildScrollView(
                // Add padding at the top to account for the app bar
                padding: const EdgeInsets.fromLTRB(16.0, 86.0, 16.0, 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Playlist Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Playlist Type Selection
                      const Text('Playlist Type:'),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('M3U'),
                              value: PlaylistTypeConstants.m3u,
                              groupValue: _playlistTypeInt,
                              onChanged: (value) {
                                setState(() {
                                  _playlistTypeInt = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('Xtream'),
                              value: PlaylistTypeConstants.xtream,
                              groupValue: _playlistTypeInt,
                              onChanged: (value) {
                                setState(() {
                                  _playlistTypeInt = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL',
                          border: OutlineInputBorder(),
                          hintText: 'http://example.com/playlist.m3u',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a URL';
                          }
                          if (!Uri.parse(value).isAbsolute) {
                            return 'Please enter a valid URL';
                          }
                          return null;
                        },
                      ),

                      if (_playlistTypeInt == PlaylistTypeConstants.xtream) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_playlistTypeInt ==
                                    PlaylistTypeConstants.xtream &&
                                (value == null || value.isEmpty)) {
                              return 'Username is required for Xtream playlists';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (_playlistTypeInt ==
                                    PlaylistTypeConstants.xtream &&
                                (value == null || value.isEmpty)) {
                              return 'Password is required for Xtream playlists';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _savePlaylist,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.playlist == null
                              ? 'Add Playlist'
                              : 'Update Playlist',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
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
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 8),
                          // Title
                          Text(
                            widget.playlist == null
                                ? 'Add Playlist'
                                : 'Edit Playlist',
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
}
