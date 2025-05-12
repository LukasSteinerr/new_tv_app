import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/playlist.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../services/playlist_service.dart';
import 'category_channels_screen.dart';
import '../widgets/time_slider_widget.dart';

class LiveTvScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const LiveTvScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
  });

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  List<Category> _categories = [];
  Map<int, String?> _categoryLogos = {};
  bool _isLoading = true;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isTimeSliderInteracting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get only Live TV categories
      final allCategories = await widget.playlistService.getPlaylistCategories(
        widget.playlist.id,
      );
      final liveTvCategories =
          allCategories.where((category) => category.isLiveTV).toList();

      // Load first channel logo for each category
      final categoryLogos = <int, String?>{};
      for (final category in liveTvCategories) {
        final channels = await widget.playlistService.getCategoryChannels(
          category.id,
        );
        if (channels.isNotEmpty) {
          categoryLogos[category.id] = channels.first.logoUrl;
        }
      }

      if (mounted) {
        setState(() {
          _categories = liveTvCategories;
          _categoryLogos = categoryLogos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToCategory(Category category) async {
    final channels = await widget.playlistService.getCategoryChannels(
      category.id,
    );
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CategoryChannelsScreen(
                category: category,
                channels: channels,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
              ? const Center(child: Text('No categories found'))
              : ListView.builder(
                padding: const EdgeInsets.only(top: 70),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return InkWell(
                    onTap: () => _navigateToCategory(category),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[800]!,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.25,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey[800]!,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      _categoryLogos[category.id] != null &&
                                              _categoryLogos[category.id]!
                                                  .isNotEmpty
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              _categoryLogos[category.id]!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) => const Icon(
                                                    Icons.live_tv,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                            ),
                                          )
                                          : const Icon(
                                            Icons.live_tv,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Removed Expanded TimeSlider from here
                          const Expanded(
                            child: SizedBox(),
                          ), // Add SizedBox to fill remaining space if needed, or adjust layout
                        ],
                      ),
                    ),
                  );
                },
              ),
          // Add the TimeSlider fixed to the right
          Positioned(
            top: 70, // Below the app bar
            right: 0,
            bottom: 0,
            width: 45, // Slightly wider fixed width for the slider
            child: Container(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withOpacity(0.8), // Optional background
              child: TimeSlider(
                selectedTime: _selectedTime,
                showBumpOut: true, // Keep or adjust as needed
                // availableHeight: // Removed this parameter
                //     MediaQuery.of(context).size.height -
                //     70, // Adjust height calculation
                onTimeChange: (TimeOfDay newTime) {
                  setState(() {
                    _selectedTime = newTime;
                  });
                },
                onInteractionStart: () {
                  setState(() {
                    _isTimeSliderInteracting = true;
                  });
                },
                onInteractionEnd: () {
                  setState(() {
                    _isTimeSliderInteracting = false;
                  });
                },
              ),
            ),
          ),
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
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.playlist.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              // Add search functionality here
                            },
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
