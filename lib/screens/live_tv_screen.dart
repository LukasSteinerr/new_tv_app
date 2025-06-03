import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import '../models/playlist.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/tv_program.dart'; // Added for EPG data
import '../services/playlist_service.dart';
// Will likely remove or change usage
import '../widgets/time_slider_widget.dart';
import 'universal_video_player.dart'; // Assuming a player screen

class LiveTvScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;
  final Function(double scrollOffset)? onScrollUpdate; // Add callback

  const LiveTvScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
    this.onScrollUpdate, // Add callback parameter
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
  Map<String, List<TvProgram>> _epgData = {}; // To store EPG data for channels

  bool _isLoading = true;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isTimeSliderInteracting = false;

  // Add ScrollController for the ListView
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _setPortraitMode(); // Ensure portrait mode on init
    _scrollController = ScrollController(); // Initialize ScrollController
    _scrollController.addListener(_notifyScrollUpdate); // Add listener
    _loadData();
  }

  void _setPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_notifyScrollUpdate); // Remove listener
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  void _notifyScrollUpdate() {
    if (widget.onScrollUpdate != null) {
      widget.onScrollUpdate!(_scrollController.offset); // Call the callback
    }
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
          _isLoading = false; // Initial data load done
        });
        // Now load EPG data
        await _loadEpgForDisplayedChannels();
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

  void _playChannel(Channel channel) async {
    // Made async
    // Navigate to a video player screen
    // For example, using UniversalVideoPlayer if it's suitable
    if (channel.streamUrl.isNotEmpty) {
      await Navigator.push(
        // await
        context,
        MaterialPageRoute(
          builder: (context) => UniversalVideoPlayer(channel: channel),
        ),
      );
      _setPortraitMode(); // Restore portrait mode
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ); // Restore UI
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
          }),
        ],
      ),
    );
  }

  Future<void> _loadEpgForDisplayedChannels() async {
    if (!mounted) return;

    final now = DateTime.now();
    DateTime selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final DateTime startTime = selectedDateTime.subtract(
      const Duration(hours: 1),
    );
    final DateTime endTime = selectedDateTime.add(const Duration(hours: 3));

    Map<String, List<TvProgram>> newEpgData = Map.from(
      _epgData,
    ); // Preserve existing data not being updated

    for (final channel in _displayedChannels) {
      if (channel.epgId != null && channel.epgId!.isNotEmpty) {
        try {
          final programs = await widget.playlistService
              .getTvProgramsForChannelInTimeRange(
                channel.epgId!,
                startTime,
                endTime,
              );
          newEpgData[channel.epgId!] = programs;
        } catch (e) {
          if (mounted) {
            // Optionally, show a less intrusive error or log it
            // print('Error loading EPG for ${channel.name}: $e');
          }
          newEpgData[channel.epgId!] = [];
        }
      } else {
        // If a channel has no epgId, ensure it has an empty list in the map
        newEpgData[channel.epgId ?? 'unknown_${channel.id}'] = [];
      }
    }

    if (mounted) {
      setState(() {
        _epgData = newEpgData;
      });
    }
  }

  Widget _buildEpgProgramList(
    List<TvProgram>? programs,
    TimeOfDay currentTime,
    String channelName,
  ) {
    if (programs == null || programs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            'No EPG data', // Shorter message
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final DateTime currentDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      currentTime.hour,
      currentTime.minute,
    );

    TvProgram? currentProgram;
    List<TvProgram> upcomingPrograms = [];

    for (var prog in programs) {
      // Ensure times are in local for comparison if they came as UTC from DB
      final progStartTimeLocal = prog.startTime.toLocal();
      final progStopTimeLocal = prog.stopTime.toLocal();

      if (currentDateTime.isAfter(
            progStartTimeLocal.subtract(const Duration(seconds: 1)),
          ) &&
          currentDateTime.isBefore(progStopTimeLocal)) {
        currentProgram = prog;
      } else if (progStartTimeLocal.isAfter(currentDateTime)) {
        upcomingPrograms.add(prog);
      }
    }

    // Sort upcoming programs by start time, just in case they aren't already
    upcomingPrograms.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Limit upcoming programs to display, e.g., next 2
    if (upcomingPrograms.length > 2) {
      upcomingPrograms = upcomingPrograms.sublist(0, 2);
    }

    List<Widget> epgItems = [];

    if (currentProgram != null) {
      epgItems.add(_buildProgramEntry(currentProgram, isCurrent: true));
    } else {
      // If no current program, find the next immediate program to show as "Up next"
      TvProgram? nextProgram;
      DateTime closestStartTime = DateTime.now().add(
        const Duration(days: 365),
      ); // Far future
      for (var prog in programs) {
        if (prog.startTime.toLocal().isAfter(currentDateTime) &&
            prog.startTime.toLocal().isBefore(closestStartTime)) {
          nextProgram = prog;
          closestStartTime = prog.startTime.toLocal();
        }
      }
      if (nextProgram != null) {
        epgItems.add(
          _buildProgramEntry(nextProgram, isCurrent: false, isNext: true),
        );
      }
    }

    for (var prog in upcomingPrograms) {
      // Avoid adding the one already potentially added as 'nextProgram' if it was also in the general upcoming list
      if (currentProgram != null && prog.id != currentProgram.id) {
        // Only add if it's different from current and not already added as the immediate next one if current is null
        if (epgItems.where((item) => item.key == ValueKey(prog.id)).isEmpty) {
          epgItems.add(_buildProgramEntry(prog, isCurrent: false));
        }
      } else if (currentProgram == null &&
          epgItems.where((item) => item.key == ValueKey(prog.id)).isEmpty) {
        // If no current program, add upcoming ones, ensuring no duplicates if one was already picked as 'next'
        epgItems.add(_buildProgramEntry(prog, isCurrent: false));
      }
    }

    if (epgItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            'No programs for this time',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        children: epgItems,
      ),
    );
  }

  Widget _buildProgramEntry(
    TvProgram program, {
    bool isCurrent = false,
    bool isNext = false,
  }) {
    final startTimeStr = _formatTime(program.startTime.toLocal());
    final stopTimeStr = _formatTime(program.stopTime.toLocal());
    String displayTitle = program.title;

    if (isCurrent) {
      displayTitle = 'Now: $displayTitle';
    } else if (isNext) {
      displayTitle = 'Next: $displayTitle';
    }

    return Padding(
      key: ValueKey(program.id), // For efficient updates
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isCurrent || isNext ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? Colors.amberAccent : Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$startTimeStr - $stopTimeStr',
            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      // AppBar is removed from here and will be in the parent XtreamPlaylistScreen
      body: Stack(
        // Keep Stack for TimeSlider and Drawer Edge Indicator
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
                controller: _scrollController, // Attach ScrollController
                padding: const EdgeInsets.only(
                  top: kToolbarHeight + 24, // Add back top padding
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
                          Expanded(
                            child: _buildEpgProgramList(
                              _epgData[channel.epgId],
                              _selectedTime,
                              channel.name,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          Positioned(
            top: kToolbarHeight + 24, // Adjust top position for parent AppBar
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
                  // Refresh EPG data when interaction ends
                  _loadEpgForDisplayedChannels();
                },
              ),
            ),
          ),
          // Drawer Edge Indicator - Keep as is, its position is relative to the Stack
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
