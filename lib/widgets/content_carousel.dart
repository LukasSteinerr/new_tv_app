import 'package:flutter/material.dart';

class ContentCarousel<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;

  const ContentCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // The Column is removed as the header is now external.
    // This widget is now just the horizontal list.
    return SizedBox(
      height: 230, // Height from reference UI's _buildMovieList
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 4.0,
        ), // Padding from reference
        itemCount: items.length,
        itemBuilder: (context, index) {
          // The direct child of ListView.builder in the reference is a Padding.
          // The MovieCard (result of itemBuilder) will handle its own width (130).
          return Padding(
            padding: const EdgeInsets.only(
              right: 12.0,
            ), // Padding between items from reference
            child: itemBuilder(items[index]),
          );
        },
      ),
    );
  }
}
