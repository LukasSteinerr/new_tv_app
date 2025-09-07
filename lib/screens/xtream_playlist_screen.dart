import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/playlist.dart';
import '../services/analytics_service.dart';
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
  final AnalyticsService analyticsService;
  final Playlist playlist;

  const XtreamPlaylistScreen({
    super.key,
    required this.playlistService,
    required this.analyticsService,
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
  bool _isSubscribed = false;

  // For AppBar opacity based on scroll
  double _appBarOpacity = 0.0; // Keep opacity state

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _objectBoxService = await ObjectBoxService.create();
    await _checkSubscription();
    _initScreens();
  }

  Future<void> _checkSubscription() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (mounted) {
        setState(() {
          _isSubscribed =
              customerInfo.entitlements.all["Pro"] != null &&
              customerInfo.entitlements.all["Pro"]!.isActive;
        });
      }
    } on PlatformException catch (e) {
      log("Error checking subscription: ${e.message}");
    }
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
      appBar:
          _currentIndex == 3
              ? AppBar(
                backgroundColor: Colors.black.withOpacity(_appBarOpacity),
                elevation: 0,
                leading: const BackButton(),
                title: const Text('Settings'),
                actions: [
                  if (_isSubscribed)
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Icon(Icons.star, color: Colors.amber, size: 24),
                    ),
                ],
              )
              : XtreamAppBar(
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
      floatingActionButton:
          _isLoading || _isSubscribed
              ? null
              : FloatingActionButton.extended(
                onPressed: () async {
                  try {
                    widget.analyticsService.logHitPaywall();
                    final paywallResult =
                        await RevenueCatUI.presentPaywallIfNeeded("Pro");
                    log("Paywall result: $paywallResult");
                    if (paywallResult == PaywallResult.purchased) {
                      widget.analyticsService.logSubscriptionStarted();
                      _checkSubscription();
                    }
                  } on PlatformException catch (e) {
                    log("Paywall error: ${e.message}");
                  }
                },
                label: const Text('Unlock Pro'),
                icon: const Icon(Icons.lock),
              ),
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
