import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import 'player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const LiveTvScreen({
    Key? key,
    required this.playlistService,
    required this.playlist,
  }) : super(key: key);

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  List<Category> _categories = [];
  List<Channel> _channels = [];
  bool _isLoading = true;
  Category? _selectedCategory;

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

      final channels = await widget.playlistService.getPlaylistChannels(
        widget.playlist.id,
      );

      setState(() {
        _categories = liveTvCategories;
        _channels = channels;
        _isLoading = false;
      });
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

  Future<void> _selectCategory(Category? category) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = category;
    });

    try {
      List<Channel> channels;
      if (category == null) {
        channels = await widget.playlistService.getPlaylistChannels(
          widget.playlist.id,
        );
      } else {
        channels = await widget.playlistService.getCategoryChannels(
          category.id,
        );
      }

      setState(() {
        _channels = channels;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading channels: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Categories horizontal list
        SizedBox(
          height: 50,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1, // +1 for "All" option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All" option
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              if (selected) {
                                _selectCategory(null);
                              }
                            },
                          ),
                        );
                      } else {
                        final category = _categories[index - 1];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(category.name),
                            selected: _selectedCategory?.id == category.id,
                            onSelected: (selected) {
                              if (selected) {
                                _selectCategory(category);
                              }
                            },
                          ),
                        );
                      }
                    },
                  ),
        ),

        // Channels list
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _channels.isEmpty
                  ? const Center(child: Text('No channels found'))
                  : ListView.builder(
                    itemCount: _channels.length,
                    itemBuilder: (context, index) {
                      final channel = _channels[index];
                      return ListTile(
                        leading:
                            channel.logoUrl != null &&
                                    channel.logoUrl!.isNotEmpty
                                ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    channel.logoUrl!,
                                  ),
                                  onBackgroundImageError: (_, __) {},
                                  child:
                                      channel.logoUrl == null ||
                                              channel.logoUrl!.isEmpty
                                          ? const Icon(Icons.tv)
                                          : null,
                                )
                                : const CircleAvatar(child: Icon(Icons.tv)),
                        title: Text(channel.name),
                        subtitle:
                            channel.category.target != null
                                ? Text(channel.category.target!.name)
                                : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PlayerScreen(channel: channel),
                            ),
                          );
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
