import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'tv_series_screen.dart';
import 'settings_screen.dart';
import '../services/objectbox_service.dart';
import '../widgets/xtream_app_bar.dart';
import '../widgets/netflix_tab_bar.dart';

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

class _XtreamPlaylistScreenState extends State<XtreamPlaylistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Widget> _screens;
  bool _isLoading = true;
  ObjectBoxService? _objectBoxService;
  bool _isSubscribed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
    _tabController.addListener(() {
      setState(() {
        _appBarOpacity = 0.0;
      });
    });
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
    _tabController.dispose();
    super.dispose();
  }

  void _updateAppBarOpacity(double scrollOffset) {
    double quickThreshold = 10.0;
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
          onScrollUpdate: _updateAppBarOpacity,
        ),
        TvSeriesScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
          onScrollUpdate: _updateAppBarOpacity,
        ),
        LiveTvScreen(
          scaffoldKey: _scaffoldKey,
          playlistService: widget.playlistService,
          playlist: widget.playlist,
          onScrollUpdate: _updateAppBarOpacity,
        ),
        SettingsScreen(
          playlistService: widget.playlistService,
          playlist: widget.playlist,
          onScrollUpdate: _updateAppBarOpacity,
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
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: XtreamAppBar(
        appBarOpacity: _appBarOpacity,
        playlistService: widget.playlistService,
        objectBoxService: _objectBoxService,
        playlist: widget.playlist,
        bottom: NetflixTabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
            Tab(text: 'Live TV'),
            Tab(text: 'Settings'),
          ],
        ),
        onOpenDrawer:
            _tabController.index == 2
                ? () {
                  _scaffoldKey.currentState?.openDrawer();
                }
                : null,
      ),
      body:
          _isLoading
              ? Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: Colors.white,
                  size: 50,
                ),
              )
              : TabBarView(controller: _tabController, children: _screens),
    );
  }
}
