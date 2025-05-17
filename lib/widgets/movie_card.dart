import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'tmdb_image.dart'; // Assuming TMDBImage can handle loading/error similar to reference

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

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
                // Using TMDBImage, assuming it can be configured
                tmdbId: movie.tmdbId,
                fallbackUrl:
                    movie.coverUrl, // Ensure movie.coverUrl is not null
                width: 130,
                height: 190, // Fixed height from reference UI
                fit: BoxFit.cover,
                isMovie: true, // Assuming this card is for movies
                // TODO: If TMDBImage doesn't have identical loading/error builders,
                // we might need to use Image.network directly here with those builders.
                // For now, TMDBImage is used for simplicity.
                // Example of direct Image.network if needed:
                // child: movie.coverUrl != null && movie.coverUrl!.isNotEmpty
                //     ? Image.network(
                //         movie.coverUrl!,
                //         width: 130,
                //         height: 190,
                //         fit: BoxFit.cover,
                //         loadingBuilder: (context, child, loadingProgress) {
                //           if (loadingProgress == null) return child;
                //           return Container(
                //             width: 130,
                //             height: 190,
                //             color: Colors.grey[850],
                //             child: Center(
                //               child: CircularProgressIndicator(
                //                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                //                 strokeWidth: 2.0,
                //                 value: loadingProgress.expectedTotalBytes != null
                //                     ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                //                     : null,
                //               ),
                //             ),
                //           );
                //         },
                //         errorBuilder: (context, error, stackTrace) => Container(
                //           width: 130,
                //           height: 190,
                //           decoration: BoxDecoration(
                //             color: Colors.grey[800],
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //           child: const Center(
                //             child: Icon(
                //               Icons.movie_filter_outlined,
                //               color: Colors.white24,
                //               size: 40,
                //             ),
                //           ),
                //         ),
                //       )
                //     : Container( // Fallback for missing coverUrl
                //         width: 130,
                //         height: 190,
                //         decoration: BoxDecoration(
                //           color: Colors.grey[800],
                //           borderRadius: BorderRadius.circular(12),
                //         ),
                //         child: const Center(
                //           child: Icon(
                //             Icons.movie_filter_outlined,
                //             color: Colors.white24,
                //             size: 40,
                //           ),
                //         ),
                //       ),
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
                  movie.name,
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
