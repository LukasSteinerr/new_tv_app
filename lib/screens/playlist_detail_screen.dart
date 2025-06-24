import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:go_router/go_router.dart';
import '../models/playlist.dart';
import '../models/channel.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import 'xtream_playlist_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    // For Xtream playlists, use the XtreamPlaylistScreen
    if (!playlist.isM3u) {
      return XtreamPlaylistScreen(
        playlistService: playlistService,
        playlist: playlist,
      );
    }

    // For M3U playlists, use the original M3U playlist screen
    return _M3uPlaylistScreen(
      playlistService: playlistService,
      playlist: playlist,
    );
  }
}

class _M3uPlaylistScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const _M3uPlaylistScreen({
    required this.playlistService,
    required this.playlist,
  });

  @override
  State<_M3uPlaylistScreen> createState() => _M3uPlaylistScreenState();
}

class _M3uPlaylistScreenState extends State<_M3uPlaylistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Category> _categories = [];
  List<Channel> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await widget.playlistService.getPlaylistCategories(
        widget.playlist.id,
      );
      final channels = await widget.playlistService.getPlaylistChannels(
        widget.playlist.id,
      );

      setState(() {
        _categories = categories;
        _channels = channels;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Categories'), Tab(text: 'All Channels')],
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: Colors.white,
                  size: 50,
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [_buildCategoriesTab(), _buildAllChannelsTab()],
              ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) {
      return const Center(child: Text('No categories found'));
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return ListTile(
          title: Text(category.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final channels = await widget.playlistService.getCategoryChannels(
              category.id,
            );
            if (mounted) {
              context.push(
                '/category-channels/${category.id}',
                extra: {'category': category, 'channels': channels},
              );
            }
          },
        );
      },
    );
  }

  Widget _buildAllChannelsTab() {
    if (_channels.isEmpty) {
      return const Center(child: Text('No channels found'));
    }

    return ListView.builder(
      itemCount: _channels.length,
      itemBuilder: (context, index) {
        final channel = _channels[index];
        return ChannelListTile(channel: channel);
      },
    );
  }
}

class CategoryChannelsScreen extends StatelessWidget {
  final Category category;
  final List<Channel> channels;

  const CategoryChannelsScreen({
    super.key,
    required this.category,
    required this.channels,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body:
          channels.isEmpty
              ? const Center(child: Text('No channels in this category'))
              : ListView.builder(
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  return ChannelListTile(channel: channels[index]);
                },
              ),
    );
  }
}

class ChannelListTile extends StatelessWidget {
  final Channel channel;

  const ChannelListTile({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          channel.logoUrl != null && channel.logoUrl!.isNotEmpty
              ? CircleAvatar(
                backgroundImage: NetworkImage(channel.logoUrl!),
                onBackgroundImageError: (_, __) {},
                child:
                    channel.logoUrl == null || channel.logoUrl!.isEmpty
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
        context.push('/player', extra: channel);
      },
    );
  }
}
