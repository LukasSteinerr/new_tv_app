import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/playlist.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../services/playlist_service.dart';
import 'category_channels_screen.dart'; // Will likely remove or change usage
import '../widgets/time_slider_widget.dart';
import 'universal_video_player.dart'; // Assuming a player screen

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Category> _categories = [];
  Map<int, String?> _categoryLogos = {}; // For drawer category logos
  List<Channel> _allLiveChannels = [];
  List<Channel> _displayedChannels = [];
  Category? _selectedCategoryInDrawer;

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
      _allLiveChannels = [];
      _displayedChannels = [];
      _categories = [];
      _categoryLogos = {};
    });

    try {
      final allCategories = await widget.playlistService.getPlaylistCategories(
        widget.playlist.id,
      );
      final liveTvCategories =
          allCategories.where((category) => category.isLiveTV).toList();

      final tempAllChannels = <Channel>[];
      final tempCategoryLogos = <int, String?>{};

      for (final category in liveTvCategories) {
        final channelsInCategory = await widget.playlistService
            .getCategoryChannels(category.id);
        tempAllChannels.addAll(channelsInCategory);
        if (channelsInCategory.isNotEmpty) {
          tempCategoryLogos[category.id] = channelsInCategory.first.logoUrl;
        }
      }

      if (mounted) {
        setState(() {
          _categories = liveTvCategories;
          _allLiveChannels = tempAllChannels;
          _displayedChannels = List.from(tempAllChannels); // Initially show all
          _categoryLogos = tempCategoryLogos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelectedInDrawer(Category? category) {
    setState(() {
      _selectedCategoryInDrawer = category;
      if (category == null) {
        // "All Channels" selected
        _displayedChannels = List.from(_allLiveChannels);
      } else {
        _displayedChannels =
            _allLiveChannels
                .where((channel) => channel.category.targetId == category.id)
                .toList();
      }
      Navigator.of(context).pop(); // Close the drawer
    });
  }

  void _playChannel(Channel channel) {
    // Navigate to a video player screen
    // For example, using UniversalVideoPlayer if it's suitable
    if (channel.streamUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UniversalVideoPlayer(channel: channel),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel stream URL is not available.')),
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Text(
              'Categories',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('All Channels'),
            onTap: () => _onCategorySelectedInDrawer(null),
            selected: _selectedCategoryInDrawer == null,
          ),
          const Divider(),
          ..._categories.map((category) {
            final logoUrl = _categoryLogos[category.id];
            return ListTile(
              leading:
                  logoUrl != null && logoUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          logoUrl,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  const Icon(Icons.live_tv, size: 30),
                        ),
                      )
                      : const Icon(Icons.live_tv, size: 30),
              title: Text(category.name),
              onTap: () => _onCategorySelectedInDrawer(category),
              selected: _selectedCategoryInDrawer?.id == category.id,
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _displayedChannels.isEmpty
              ? Center(
                child: Text(
                  _selectedCategoryInDrawer == null
                      ? 'No channels found'
                      : 'No channels in this category',
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.only(
                  top: 70,
                  bottom: 10,
                  left: 10,
                  right: 55,
                ), // Adjusted right padding for TimeSlider
                itemCount: _displayedChannels.length,
                itemBuilder: (context, index) {
                  final channel = _displayedChannels[index];
                  return InkWell(
                    onTap: () => _playChannel(channel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                channel.logoUrl != null &&
                                        channel.logoUrl!.isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        channel.logoUrl!,
                                        width: 40, // Adjusted size
                                        height: 40, // Adjusted size
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[850],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.tv,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                      ),
                                    )
                                    : Container(
                                      width: 40, // Adjusted size
                                      height: 40, // Adjusted size
                                      decoration: BoxDecoration(
                                        color: Colors.grey[850],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.tv,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                const SizedBox(height: 8),
                                Text(
                                  channel.name,
                                  style: const TextStyle(
                                    fontSize: 12, // Adjusted size
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Expanded(
                            child: SizedBox(), // Empty column on the right
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          Positioned(
            top: 70,
            right: 0,
            bottom: 0,
            width: 45,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              child: TimeSlider(
                selectedTime: _selectedTime,
                showBumpOut: true,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ), // Reduced horizontal padding
                      child: Row(
                        children: [
                          // IconButton for drawer removed
                          // const SizedBox(width: 8), // Keep or remove depending on desired title spacing
                          Expanded(
                            // Added Expanded for title
                            child: Text(
                              widget.playlist.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Removed Spacer to allow title to take more space if needed
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              // TODO: Add search functionality for channels
                            },
                          ),
                          IconButton(
                            // Keep back button if needed, or remove if drawer is primary navigation
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Drawer Edge Indicator
          Positioned(
            left: 0,
            top:
                MediaQuery.of(context).size.height / 2 -
                30, // Centering 60px height
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              // Optional: Add onHorizontalDragUpdate for swipe-to-open
              child: Container(
                width: 5, // Width of the line
                height: 60, // Height of the line
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomRight: Radius.circular(3),
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
