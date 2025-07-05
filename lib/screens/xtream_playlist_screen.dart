import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'tv_series_screen.dart';
import 'settings_screen.dart';
import '../services/objectbox_service.dart';
import '../widgets/xtream_app_bar.dart';
import '../widgets/xtream_bottom_nav_bar.dart';

class XtreamPlaylistScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const XtreamPlaylistScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
  });

  @override
  State<XtreamPlaylistScreen> createState() => _XtreamPlaylistScreenState();
}

class _XtreamPlaylistScreenState extends State<XtreamPlaylistScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _isLoading = true;
  ObjectBoxService? _objectBoxService;

  // For AppBar opacity based on scroll
  double _appBarOpacity = 0.0; // Keep opacity state

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _objectBoxService = await ObjectBoxService.create();
    _initScreens();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateAppBarOpacity(double scrollOffset) {
    double quickThreshold =
        10.0; // Transition to full target opacity over these many pixels
    double targetOpacity = 0.7;
    double newOpacity;

    if (scrollOffset <= 0) {
      newOpacity = 0.0;
    } else {
      newOpacity = (scrollOffset / quickThreshold).clamp(0.0, targetOpacity);
    }

    if (newOpacity != _appBarOpacity) {
      if (mounted) {
        setState(() {
          _appBarOpacity = newOpacity;
        });
      }
    }
  }

  Future<void> _initScreens() async {
    try {
      _screens = [
        MoviesScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
          onScrollUpdate: _updateAppBarOpacity, // Pass the callback
        ),
        TvSeriesScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
          onScrollUpdate: _updateAppBarOpacity, // Pass the callback
        ),
        LiveTvScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
          onScrollUpdate: _updateAppBarOpacity, // Pass the callback
        ),
        SettingsScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
          onScrollUpdate: _updateAppBarOpacity, // Pass the callback
        ),
      ];
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      backgroundColor: Colors.black, // Set background color
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
      appBar: XtreamAppBar(
        appBarOpacity: _appBarOpacity,
        playlistService: widget.playlistService,
        objectBoxService: _objectBoxService,
        playlist: widget.playlist,
      ),
      body:
          _isLoading
              ? Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: Colors.white,
                  size: 50,
                ),
              )
              : IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: XtreamBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _appBarOpacity = 0.0; // Reset AppBar opacity to fully transparent
          });
        },
      ),
    );
  }
}
