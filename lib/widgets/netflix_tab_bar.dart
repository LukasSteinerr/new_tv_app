import 'package:flutter/material.dart';

class NetflixTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Widget> tabs;

  const NetflixTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: true,
      indicator: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.red, width: 3.0)),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey[400],
      labelStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 16.0),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
