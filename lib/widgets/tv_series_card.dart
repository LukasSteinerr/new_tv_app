import 'package:flutter/material.dart';
import '../models/tv_series.dart';
import 'tmdb_image.dart'; // Assuming TMDBImage can handle loading/error similar to reference

class TvSeriesCard extends StatelessWidget {
  final TvSeries series;
  final VoidCallback onTap;

  const TvSeriesCard({super.key, required this.series, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        // Constrain the width of the card
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0), // From reference UI
              child: TMDBImage(
                tmdbId: series.tmdbId,
                fallbackUrl: series.coverUrl,
                width: 130,
                height: 190, // Fixed height from reference UI
                fit: BoxFit.cover,
                isMovie: false, // Important: set to false for TV Series
                // TODO: If TMDBImage doesn't have identical loading/error builders
                // from reference UI, might need to use Image.network directly.
              ),
            ),
            const SizedBox(height: 6.0), // Reduced spacing
            // Wrap the SizedBox containing the Text with Expanded
            Expanded(
              child: SizedBox(
                // To constrain text width and allow ellipsis
                width:
                    130, // Still useful to constrain width for horizontal layout
                child: Text(
                  series.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // From reference UI
                    fontWeight: FontWeight.w500, // From reference UI
                  ),
                  maxLines: 1, // Changed to 1 line
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
