import 'package:flutter/material.dart';
import '../models/tv_series.dart';
import 'tmdb_image.dart';
import '../constants/app_theme.dart';

class TvSeriesCard extends StatelessWidget {
  final TvSeries series;
  final VoidCallback onTap;

  const TvSeriesCard({super.key, required this.series, required this.onTap});

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
                tmdbId: series.tmdbId,
                fallbackUrl: series.coverUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                isMovie: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
