import 'package:flutter/material.dart';

class ContentCarousel<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;

  const ContentCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  @override
  State<ContentCarousel<T>> createState() => _ContentCarouselState<T>();
}

class _ContentCarouselState<T> extends State<ContentCarousel<T>>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final Map<int, Widget> _cachedWidgets = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cachedWidgets.clear();
    super.dispose();
  }

  Widget _buildItem(int index) {
    // Cache built widgets to avoid rebuilding
    if (!_cachedWidgets.containsKey(index)) {
      _cachedWidgets[index] = Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: widget.itemBuilder(widget.items[index]),
      );
    }
    return _cachedWidgets[index]!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 230,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16.0, right: 4.0),
        itemCount: widget.items.length,
        cacheExtent: 800, // Cache 800 pixels worth of items
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) => _buildItem(index),
      ),
    );
  }
}
