import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:async';
import 'dart:io';
import '../models/movie.dart';
import '../models/tv_episode.dart';
import '../models/channel.dart';

class UniversalVideoPlayer extends StatefulWidget {
  // Content parameters - only one of these should be provided
  final Movie? movie;
  final TvEpisode? episode;
  final Channel? channel;
  final String? localPath; // New parameter for local file path

  // Constructor with named parameters for different content types
  const UniversalVideoPlayer({
    super.key,
    this.movie,
    this.episode,
    this.channel,
    this.localPath, // Add to constructor
  }) : assert(
         (movie != null && episode == null && channel == null) ||
             (movie == null && episode != null && channel == null) ||
             (movie == null && episode == null && channel != null),
         'Exactly one of movie, episode, or channel must be provided',
       );

  @override
  State<UniversalVideoPlayer> createState() => _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState extends State<UniversalVideoPlayer>
    with WidgetsBindingObserver {
  VlcPlayerController? _controller;
  bool _showControls = false; // Controls visibility flag
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    // Check if a local path is provided
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      _controller = VlcPlayerController.file(
        File(widget.localPath!),
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
          ]),
          http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
          rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
        ),
      );
    } else {
      // Get the appropriate stream URL based on content type
      final String streamUrl = _getStreamUrl();

      _controller = VlcPlayerController.network(
        streamUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
          ]),
          http: VlcHttpOptions([VlcHttpOptions.httpReconnect(true)]),
          rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
        ),
      );
    }

    _controller!.addOnInitListener(() async {
      await _controller!.startRendererScanning();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pause the video when the app is in the background
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
    // Resume the video when the app is in the foreground
    if (state == AppLifecycleState.resumed) {
      _controller?.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // The controller is disposed manually via _handleClose,
    // but as a fallback, we can dispose it here.
    if (_controller != null) {
      _controller!.dispose();
    }

    // Reset orientation and UI mode when leaving the player
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  Future<void> _handleClose() async {
    final VlcPlayerController? controllerToDispose = _controller;
    if (mounted) {
      setState(() {
        _controller = null; // Remove the player from the tree
      });
    }

    await controllerToDispose?.stop();
    await controllerToDispose?.dispose();

    if (mounted) {
      Navigator.of(context).pop();
    }
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
    if (_controller == null || !_controller!.value.isPlaying) return;

    final subtitleTracks = await _controller!.getSpuTracks();

    if (subtitleTracks.isNotEmpty) {
      if (!mounted) return;
      final selectedSubId = await showDialog<int>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.closed_caption,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Select Subtitles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subtitle tracks list
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: subtitleTracks.keys.length + 1,
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.1),
                              indent: 16,
                              endIndent: 16,
                            ),
                        itemBuilder: (context, index) {
                          if (index == subtitleTracks.keys.length) {
                            return _buildSubtitleItem(
                              icon: Icons.subtitles_off,
                              title: 'Disable Subtitles',
                              subtitle: 'Turn off all subtitles',
                              onTap: () => Navigator.pop(context, -1),
                            );
                          }
                          final key = subtitleTracks.keys.elementAt(index);
                          final trackName = subtitleTracks.values.elementAt(
                            index,
                          );
                          return _buildSubtitleItem(
                            icon: Icons.subtitles,
                            title: trackName,
                            subtitle: 'Subtitle track ${index + 1}',
                            onTap: () => Navigator.pop(context, key),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (selectedSubId != null) {
        await _controller!.setSpuTrack(selectedSubId);
      }
    }
  }

  Widget _buildSubtitleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.orange[300], size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getRendererDevices() async {
    if (_controller == null) return;
    final castDevices = await _controller!.getRendererDevices();

    if (castDevices.isNotEmpty) {
      if (!mounted) return;
      final selectedCastDeviceName = await showDialog<String>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cast, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Cast to Device',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Device list
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: castDevices.keys.length + 1,
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.1),
                              indent: 16,
                              endIndent: 16,
                            ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildCastDeviceItem(
                              icon: Icons.smartphone,
                              title: 'Play on This Device',
                              subtitle: 'Current device',
                              onTap: () => Navigator.pop(context, null),
                            );
                          }
                          final key = castDevices.keys.elementAt(index - 1);
                          final name = castDevices[key] ?? 'Unknown device';
                          return _buildCastDeviceItem(
                            icon: Icons.cast_connected,
                            title: name,
                            subtitle: 'Available for casting',
                            onTap: () => Navigator.pop(context, name),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (selectedCastDeviceName != null) {
        await _controller!.castToRenderer(selectedCastDeviceName);
      } else {
        // User selected to play on device, stop casting
        await _controller!
            .startRendererScanning(); // This will stop casting and start scanning again
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No Cast Devices Found!')));
    }
  }

  Widget _buildCastDeviceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue[300], size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleClose();
        return false; // We handle the pop manually
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body:
            _controller == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  children: [
                    // Video player takes the full screen
                    Center(
                      child: VlcPlayer(
                        controller: _controller!,
                        aspectRatio: 16 / 9,
                        placeholder: const Center(
                          child: CircularProgressIndicator(),
                        ),
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
      ),
    );
  }

  Widget _buildControlsOverlay() {
    if (_controller == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
      valueListenable: _controller!,
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
                        onPressed: _handleClose,
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
                                    _controller!.seekTo(newPosition);
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
                                  () => _controller!.seekTo(
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
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.forward_10,
                                color: Colors.white,
                              ),
                              onPressed:
                                  () => _controller!.seekTo(
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
