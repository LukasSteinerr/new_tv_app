import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import 'universal_video_player.dart';
import 'category_channels_screen.dart';

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

  void _navigateToSeeAllChannels() {
    if (_channels.isEmpty) return;

    final title = _selectedCategory?.name ?? 'All Channels';
    final category =
        _selectedCategory ??
        Category(name: title, contentType: ContentType.liveTV);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CategoryChannelsScreen(category: category, channels: _channels),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the standard app bar
      extendBodyBehindAppBar: true, // Allow content to go behind app bar
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Add padding at the top to account for the app bar
              const SizedBox(height: 70),
              // Categories horizontal list
              SizedBox(
                height: 50,
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              _categories.length + 1, // +1 for "All" option
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // "All" option
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: ChoiceChip(
                                  label: Text(category.name),
                                  selected:
                                      _selectedCategory?.id == category.id,
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

              // Category title and See All button
              if (!_isLoading && _channels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory?.name ?? 'All Channels',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToSeeAllChannels,
                        child: const Text('See All'),
                      ),
                    ],
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
                                      : const CircleAvatar(
                                        child: Icon(Icons.tv),
                                      ),
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
                                        (context) => UniversalVideoPlayer(
                                          channel: channel,
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
              ),
            ],
          ),

          // Custom app bar with blur effect
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
                          // Back button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          // Title - Show playlist name
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
                          // Search button
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
