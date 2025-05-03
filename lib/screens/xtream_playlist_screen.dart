import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'tv_series_screen.dart';
import 'settings_screen.dart';

class XtreamPlaylistScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const XtreamPlaylistScreen({
    Key? key,
    required this.playlistService,
    required this.playlist,
  }) : super(key: key);

  @override
  State<XtreamPlaylistScreen> createState() => _XtreamPlaylistScreenState();
}

class _XtreamPlaylistScreenState extends State<XtreamPlaylistScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  Future<void> _initScreens() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _screens = [
        MoviesScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
        ),
        TvSeriesScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
        ),
        LiveTvScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
        ),
        SettingsScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
        ),
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading content: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Movies'),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'TV Shows'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live TV'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
