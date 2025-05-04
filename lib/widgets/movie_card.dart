import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'tmdb_image.dart';
import '../constants/app_theme.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate fixed dimensions based on the aspect ratio
        final width = constraints.maxWidth;
        final height = width * 3 / 2; // 2:3 aspect ratio

        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: width,
              height: height,
              child: TMDBImage(
                tmdbId: movie.tmdbId,
                fallbackUrl: movie.coverUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                isMovie: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
