import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../screens/download_screen.dart';
import '../screens/my_list_screen.dart';
import '../screens/search_screen.dart';
import '../services/objectbox_service.dart';
import '../services/playlist_service.dart';

class XtreamAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double appBarOpacity;
  final PlaylistService playlistService;
  final ObjectBoxService? objectBoxService;
  final Playlist playlist;

  const XtreamAppBar({
    super.key,
    required this.appBarOpacity,
    required this.playlistService,
    required this.objectBoxService,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(appBarOpacity),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: const BackButton(color: Colors.white),
      titleSpacing: 0,
      title: const SizedBox.shrink(),
      actions: [
        IconButton(
          icon: const Icon(Icons.list, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MyListScreen(playlistService: playlistService),
              ),
            );
          },
          tooltip: 'My List',
        ),
        IconButton(
          icon: const Icon(
            Icons.download_outlined,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DownloadScreen()),
            );
          },
          tooltip: 'Download',
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 30),
          onPressed: () {
            if (objectBoxService != null) {
              showSearch(
                context: context,
                delegate: SearchScreen(
                  objectBoxService: objectBoxService!,
                  playlistService: playlistService,
                ),
              );
            }
          },
          tooltip: 'Search',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
