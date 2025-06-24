import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../models/tv_episode.dart';
import '../models/channel.dart';
import '../widgets/time_slider_widget.dart';

class UniversalVideoPlayer extends StatefulWidget {
  // Content parameters - only one of these should be provided
  final Movie? movie;
  final TvEpisode? episode;
  final Channel? channel;

  // Constructor with named parameters for different content types
  const UniversalVideoPlayer({
    super.key,
    this.movie,
    this.episode,
    this.channel,
  }) : assert(
         (movie != null && episode == null && channel == null) ||
             (movie == null && episode != null && channel == null) ||
             (movie == null && episode == null && channel != null),
         'Exactly one of movie, episode, or channel must be provided',
       );

  @override
  State<UniversalVideoPlayer> createState() => _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState extends State<UniversalVideoPlayer> {
  late VlcPlayerController _controller;
  bool _showControls = false; // Controls visibility flag
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();

    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide status bar and navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializePlayer() {
    // Get the appropriate stream URL based on content type
    final String streamUrl = _getStreamUrl();

    _controller = VlcPlayerController.network(
      streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(2000)]),
        http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
        rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
      ),
    );
    _controller.addOnInitListener(() async {
      await _controller.startRendererScanning();
    });
  }

  String _getStreamUrl() {
    if (widget.movie != null) {
      return widget.movie!.streamUrl;
    } else if (widget.episode != null) {
      return widget.episode!.streamUrl;
    } else if (widget.channel != null) {
      return widget.channel!.streamUrl;
    } else {
      throw Exception('No valid content provided to the player');
    }
  }

  @override
  void dispose() {
    _controller.stopRendererScanning();
    _controller.dispose();

    // Reset orientation and UI mode when leaving the player
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    // Auto-hide controls after 3 seconds
    _controlsTimer?.cancel();
    if (_showControls) {
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  // Format duration to display as HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  // Get the title of the current content
  String _getContentTitle() {
    if (widget.movie != null) {
      return widget.movie!.name;
    } else if (widget.episode != null) {
      final seriesName = widget.episode!.series.target?.name ?? '';
      return '$seriesName - ${widget.episode!.title}';
    } else if (widget.channel != null) {
      return widget.channel!.name;
    } else {
      return 'Now Playing';
    }
  }

  Future<void> _getSubtitleTracks() async {
    if (!_controller.value.isPlaying) return;

    final subtitleTracks = await _controller.getSpuTracks();

    if (subtitleTracks.isNotEmpty) {
      if (!mounted) return;
      final selectedSubId = await showDialog<int>(
        context: context,
        builder: (BuildContext _) {
          return AlertDialog(
            title: const Text('Select Subtitle'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: subtitleTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < subtitleTracks.keys.length
                          ? subtitleTracks.values.elementAt(index)
                          : 'Disable',
                    ),
                    onTap: () {
                      context.pop(
                        index < subtitleTracks.keys.length
                            ? subtitleTracks.keys.elementAt(index)
                            : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedSubId != null) {
        await _controller.setSpuTrack(selectedSubId);
      }
    }
  }

  Future<void> _getRendererDevices() async {
    final castDevices = await _controller.getRendererDevices();

    if (castDevices.isNotEmpty) {
      if (!mounted) return;
      final selectedCastDeviceName = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Cast Device'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: castDevices.keys.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: const Text('Play on device'),
                      onTap: () {
                        context.pop(null);
                      },
                    );
                  }
                  final key = castDevices.keys.elementAt(index - 1);
                  final name = castDevices[key];
                  return ListTile(
                    title: Text(name ?? 'Unknown device'),
                    onTap: () {
                      context.pop(name);
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedCastDeviceName != null) {
        await _controller.castToRenderer(selectedCastDeviceName);
      } else {
        // User selected to play on device, stop casting
        await _controller
            .startRendererScanning(); // This will stop casting and start scanning again
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No Cast Devices Found!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player takes the full screen
          Center(
            child: VlcPlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
              placeholder: const Center(child: CircularProgressIndicator()),
            ),
          ),
          // Gesture detector covering the entire screen
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Toggle controls visibility when tapped
                _toggleControls();
              },
              // Use a transparent container to ensure the gesture detector covers everything
              child: Container(color: Colors.transparent),
            ),
          ),
          // Controls overlay that appears when tapped
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, VlcPlayerValue value, child) {
        // Calculate current position and total duration
        final position = value.position;
        final duration = value.duration;

        // Calculate progress as a value between 0.0 and 1.0
        final progress =
            duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

        // Make sure controls are interactive
        return GestureDetector(
          // This will prevent taps on controls from being passed to the background GestureDetector
          onTap: () {
            // Reset the auto-hide timer when interacting with controls
            _controlsTimer?.cancel();
            _controlsTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showControls = false;
                });
              }
            });
          },
          child: Stack(
            children: [
              // Top bar with title and close button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withAlpha(179), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getContentTitle(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom controls bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(179), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Seek bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Current position
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(color: Colors.white),
                            ),

                            // Slider for seeking
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  activeTrackColor: Colors.red,
                                  inactiveTrackColor: Colors.grey[600],
                                  thumbColor: Colors.red,
                                  overlayColor: Colors.red.withAlpha(77),
                                ),
                                child: Slider(
                                  value: progress.clamp(0.0, 1.0),
                                  onChanged: (value) {
                                    final newPosition = Duration(
                                      milliseconds:
                                          (value * duration.inMilliseconds)
                                              .round(),
                                    );
                                    _controller.seekTo(newPosition);
                                  },
                                ),
                              ),
                            ),

                            // Total duration
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      // Playback controls
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.replay_10,
                                color: Colors.white,
                              ),
                              onPressed:
                                  () => _controller.seekTo(
                                    Duration(seconds: position.inSeconds - 10),
                                  ),
                            ),
                            IconButton(
                              iconSize: 48,
                              icon: Icon(
                                value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (value.isPlaying) {
                                  _controller.pause();
                                } else {
                                  _controller.play();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.forward_10,
                                color: Colors.white,
                              ),
                              onPressed:
                                  () => _controller.seekTo(
                                    Duration(seconds: position.inSeconds + 10),
                                  ),
                            ),
                            // Subtitle button
                            IconButton(
                              icon: const Icon(
                                Icons.closed_caption,
                                color: Colors.white,
                              ),
                              onPressed: _getSubtitleTracks,
                            ),
                            // Cast button
                            IconButton(
                              icon: const Icon(Icons.cast, color: Colors.white),
                              onPressed: _getRendererDevices,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
