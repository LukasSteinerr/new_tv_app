import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'tmdb_image.dart';
import '../constants/app_theme.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({Key? key, required this.movie, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: AspectRatio(
          aspectRatio: 2 / 3, // Netflix-style poster ratio
          child: TMDBImage(
            tmdbId: movie.tmdbId,
            fallbackUrl: movie.coverUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            isMovie: true,
          ),
        ),
      ),
    );
  }
}
