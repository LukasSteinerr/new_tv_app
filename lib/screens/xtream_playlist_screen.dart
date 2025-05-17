import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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

  // For AppBar opacity based on scroll
  double _appBarOpacity = 0.0; // Keep opacity state

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  @override
  void dispose() {
    // No ScrollController to dispose here
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
    setState(() {
      _isLoading = true;
    });

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
      backgroundColor: Colors.black, // Set background color
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
      appBar: AppBar(
        // Implement the styled AppBar
        backgroundColor: Colors.black.withOpacity(
          _appBarOpacity,
        ), // Dynamic opacity
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Prevent M3 surface tint
        leadingWidth: 60, // As per reference UI
        leading: GestureDetector(
          // Leading profile avatar
          onTap: () {
            // TODO: Navigate to Profile Screen (if exists)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Profile tapped!')));
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: CircleAvatar(
              radius: 22, // As per reference UI
              backgroundImage: const NetworkImage(
                'https://xsgames.co/randomusers/assets/avatars/male/74.jpg', // Placeholder image
              ),
              backgroundColor: Colors.grey[800],
            ),
          ),
        ),
        titleSpacing: 0, // As per reference UI
        title: const SizedBox.shrink(), // Empty title as per reference UI
        actions: [
          // Actions (Cast, Download, Search)
          IconButton(
            icon: const Icon(
              Icons.cast,
              color: Colors.white,
              size: 28,
            ), // As per reference UI
            onPressed: () {
              // TODO: Implement Cast functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cast tapped!')));
            },
            tooltip: 'Cast',
          ),
          IconButton(
            icon: const Icon(
              Icons.download_outlined,
              color: Colors.white,
              size: 28, // As per reference UI
            ),
            onPressed: () {
              // TODO: Implement Download functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Download tapped!')));
            },
            tooltip: 'Download',
          ),
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 30,
            ), // As per reference UI
            onPressed: () {
              // TODO: Implement Search functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Search tapped!')));
            },
            tooltip: 'Search',
          ),
          const SizedBox(width: 8), // Spacing as per reference UI
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
              : IndexedStack(
                // Use IndexedStack to keep screens alive
                index: _currentIndex,
                children: _screens,
              ),
      bottomNavigationBar: Theme(
        // Wrap with Theme to remove splash/highlight
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black, // Styled as per reference UI
          selectedItemColor: Colors.white, // Styled as per reference UI
          unselectedItemColor: Colors.grey[700], // Styled as per reference UI
          type: BottomNavigationBarType.fixed, // Already fixed
          showSelectedLabels: false, // Hide labels as per reference UI
          showUnselectedLabels: false, // Hide labels as per reference UI
          iconSize: 26, // Styled as per reference UI
          currentIndex: _currentIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Movies'),
            BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'TV Shows'),
            BottomNavigationBarItem(
              icon: Icon(Icons.live_tv),
              label: 'Live TV',
            ),
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
      ),
    );
  }
}
