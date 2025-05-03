import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/channel.dart';
import 'player_screen.dart';

class CategoryChannelsScreen extends StatelessWidget {
  final Category category;
  final List<Channel> channels;

  const CategoryChannelsScreen({
    Key? key,
    required this.category,
    required this.channels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: channels.isEmpty
          ? const Center(child: Text('No channels in this category'))
          : ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return ListTile(
                  leading: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            channel.logoUrl!,
                          ),
                          onBackgroundImageError: (_, __) {},
                          child: channel.logoUrl == null || channel.logoUrl!.isEmpty
                              ? const Icon(Icons.tv)
                              : null,
                        )
                      : const CircleAvatar(child: Icon(Icons.tv)),
                  title: Text(channel.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(channel: channel),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
