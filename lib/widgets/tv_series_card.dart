import 'package:flutter/material.dart';
import '../models/tv_series.dart';
import 'tmdb_image.dart';
import '../constants/app_theme.dart';

class TvSeriesCard extends StatelessWidget {
  final TvSeries series;
  final VoidCallback onTap;

  const TvSeriesCard({Key? key, required this.series, required this.onTap})
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
            tmdbId: series.tmdbId,
            fallbackUrl: series.coverUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            isMovie: false,
          ),
        ),
      ),
    );
  }
}
