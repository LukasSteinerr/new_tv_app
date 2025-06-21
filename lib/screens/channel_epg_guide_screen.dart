import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/channel.dart';
import '../models/tv_program.dart';
import '../services/playlist_service.dart';
import 'universal_video_player.dart';
import 'package:intl/intl.dart';

class ChannelEpgGuideScreen extends StatefulWidget {
  final Channel channel;
  final PlaylistService playlistService;

  const ChannelEpgGuideScreen({
    super.key,
    required this.channel,
    required this.playlistService,
  });

  @override
  _ChannelEpgGuideScreenState createState() => _ChannelEpgGuideScreenState();
}

class _ChannelEpgGuideScreenState extends State<ChannelEpgGuideScreen> {
  late Future<List<TvProgram>> _epgFuture;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _epgFuture = _fetchEpgData();
  }

  Future<List<TvProgram>> _fetchEpgData() async {
    if (widget.channel.epgId == null || widget.channel.epgId!.isEmpty) {
      return [];
    }
    // Fetch for a 24 hour period
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 12));
    final endTime = now.add(const Duration(hours: 12));
    return widget.playlistService.getTvProgramsForChannelInTimeRange(
      widget.channel.epgId!,
      startTime,
      endTime,
    );
  }

  void _playChannel() {
    if (widget.channel.streamUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UniversalVideoPlayer(channel: widget.channel),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel stream URL is not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.name),
        actions: [
          if (widget.channel.logoUrl != null &&
              widget.channel.logoUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Image.network(
                widget.channel.logoUrl!,
                width: 36,
                height: 36,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(Icons.tv),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<TvProgram>>(
        future: _epgFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading EPG: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No EPG data available for this channel.'),
            );
          }

          final programs = snapshot.data!;
          final now = DateTime.now();

          // Find index of current program
          int currentIndex = programs.indexWhere(
            (p) =>
                now.isAfter(p.startTime.toLocal()) &&
                now.isBefore(p.stopTime.toLocal()),
          );

          return ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            initialScrollIndex: currentIndex != -1 ? currentIndex : 0,
            initialAlignment: 0.5,
            itemCount: programs.length,
            padding: const EdgeInsets.only(top: 8.0), // Add some padding
            itemBuilder: (context, index) {
              final program = programs[index];
              final isCurrent = index == currentIndex;
              final startTimeStr = DateFormat.Hm().format(
                program.startTime.toLocal(),
              );
              final endTimeStr = DateFormat.Hm().format(
                program.stopTime.toLocal(),
              );

              return InkWell(
                onTap: isCurrent ? _playChannel : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  decoration: BoxDecoration(
                    color:
                        isCurrent
                            ? Colors.blueGrey.withOpacity(0.3)
                            : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
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
                        child: Center(
                          child: Text(
                            '$startTimeStr - $endTimeStr',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                program.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (program.description != null &&
                                  program.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    program.description!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (isCurrent)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: LinearProgressIndicator(
                                    value: _calculateProgress(
                                      program.startTime,
                                      program.stopTime,
                                    ),
                                    backgroundColor: Colors.grey[700],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.amber,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final now = DateTime.now();
          _epgFuture.then((programs) {
            int currentIndex = programs.indexWhere(
              (p) =>
                  now.isAfter(p.startTime.toLocal()) &&
                  now.isBefore(p.stopTime.toLocal()),
            );
            if (currentIndex != -1) {
              _itemScrollController.scrollTo(
                index: currentIndex,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                alignment: 0.5,
              );
            }
          });
        },
        mini: true,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  double _calculateProgress(DateTime start, DateTime stop) {
    final now = DateTime.now();
    if (now.isBefore(start) || now.isAfter(stop)) {
      return 0.0;
    }
    final totalDuration = stop.difference(start).inSeconds;
    if (totalDuration <= 0) {
      return 0.0;
    }
    final elapsed = now.difference(start).inSeconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }
}
