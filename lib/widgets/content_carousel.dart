import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ContentCarousel<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final VoidCallback? onSeeAllPressed;

  const ContentCarousel({
    Key? key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.onSeeAllPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with Netflix styling - fixed to prevent overflow
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
          child: Row(
            children: [
              // Category name with ellipsis to prevent overflow
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Fixed-width See All button
              if (onSeeAllPressed != null)
                SizedBox(
                  width: 100, // Fixed width for the button
                  child: TextButton(
                    onPressed: onSeeAllPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'See All',
                          style: TextStyle(
                            color: AppColors.netflixTextSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.netflixTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Content carousel with Netflix styling
        SizedBox(
          height: 220, // Taller for Netflix style
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 140, // Wider for Netflix style
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content item (poster)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: itemBuilder(items[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
