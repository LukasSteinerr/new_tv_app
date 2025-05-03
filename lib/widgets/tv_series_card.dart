import 'package:flutter/material.dart';
import '../models/tv_series.dart';
import 'tmdb_image.dart';

class TvSeriesCard extends StatelessWidget {
  final TvSeries series;
  final VoidCallback onTap;

  const TvSeriesCard({Key? key, required this.series, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TMDBImage(
                tmdbId: series.tmdbId,
                fallbackUrl: series.coverUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                isMovie: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                series.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
