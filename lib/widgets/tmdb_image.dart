import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/tmdb_image_provider.dart';
import '../widgets/netflix_style_loading.dart';

/// A widget that displays an image from TMDB if available, otherwise falls back to a provided URL
class TMDBImage extends StatefulWidget {
  final String? tmdbId;
  final String? fallbackUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final bool isMovie; // true for movies, false for TV shows

  const TMDBImage({
    super.key,
    required this.tmdbId,
    this.fallbackUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
    this.isMovie = true,
  });

  @override
  State<TMDBImage> createState() => _TMDBImageState();
}

class _TMDBImageState extends State<TMDBImage> {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  Future<String?>? _imageUrlFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future that will fetch the image URL
    _imageUrlFuture = _getImageUrl();
  }

  @override
  void didUpdateWidget(TMDBImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the TMDB ID or fallback URL changes, create a new future
    if (oldWidget.tmdbId != widget.tmdbId ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      setState(() {
        _imageUrlFuture = _getImageUrl();
      });
    }
  }

  Future<String?> _getImageUrl() async {
    // Guard against cases where there's no ID and no fallback
    if ((widget.tmdbId == null || widget.tmdbId!.isEmpty) &&
        (widget.fallbackUrl == null || widget.fallbackUrl!.isEmpty)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return null;

    // First, check for a cached URL in SharedPreferences
    if (widget.tmdbId != null && widget.tmdbId!.isNotEmpty) {
      final cachedUrl = prefs.getString(widget.tmdbId!);
      if (cachedUrl != null) {
        return cachedUrl;
      }
    }

    // If no cached URL, fetch from the TMDB service
    try {
      String? url;
      if (widget.tmdbId != null && widget.tmdbId!.isNotEmpty) {
        url =
            widget.isMovie
                ? await _imageProvider.getPosterUrl(
                  widget.tmdbId,
                  widget.fallbackUrl,
                )
                : await _imageProvider.getTvPosterUrl(
                  widget.tmdbId,
                  widget.fallbackUrl,
                );

        // Cache the newly fetched URL
        if (url != null && url.isNotEmpty) {
          await prefs.setString(widget.tmdbId!, url);
        }
      } else if (widget.fallbackUrl != null && widget.fallbackUrl!.isNotEmpty) {
        // If no TMDB ID but we have a fallback, use it
        url = widget.fallbackUrl;
      }
      return url;
    } catch (e) {
      // On error, return the fallback URL as a last resort
      return widget.fallbackUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a SizedBox with the specified dimensions as the base
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FutureBuilder<String?>(
        future: _imageUrlFuture,
        builder: (context, snapshot) {
          // Case 1: The future is still running
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const NetflixStyleLoading(
              width: double.infinity,
              height: double.infinity,
            );
          }

          // Case 2: The future completed, but with no data or an error
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return _buildPlaceholder();
          }

          // Case 3: The future completed successfully with an image URL
          final imageUrl = snapshot.data!;
          return CachedNetworkImage(
            imageUrl: imageUrl,
            // Use imageBuilder for custom display logic
            imageBuilder:
                (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      8.0,
                    ), // Your custom decoration
                    image: DecorationImage(
                      image: imageProvider,
                      fit: widget.fit,
                    ),
                  ),
                ),
            // Placeholder for when CachedNetworkImage is downloading
            placeholder:
                (context, url) => const NetflixStyleLoading(
                  width: double.infinity,
                  height: double.infinity,
                ),
            // Error widget for when the URL fails to load
            errorWidget: (context, url, error) => _buildPlaceholder(),
          );
        },
      ),
    );
  }

  // Helper method to build a consistent placeholder
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Icon(
          widget.isMovie ? Icons.movie : Icons.tv,
          color: Colors.white54,
          size: 40, // Fixed size icon
        ),
      ),
    );
  }
}
