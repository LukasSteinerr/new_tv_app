import 'package:flutter/material.dart';
import 'universal_video_player.dart';
import '../models/category.dart';
import '../models/channel.dart';
import 'package:go_router/go_router.dart';

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
        context.push('/video-player', extra: channel);
      },
    );
  }
}
