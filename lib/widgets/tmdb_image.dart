import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

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
    Key? key,
    required this.tmdbId,
    this.fallbackUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
    this.isMovie = true,
  }) : super(key: key);

  @override
  State<TMDBImage> createState() => _TMDBImageState();
}

class _TMDBImageState extends State<TMDBImage> {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Set loading to false immediately if we have no TMDB ID and no fallback URL
    // This ensures we show a placeholder right away
    if ((widget.tmdbId == null || widget.tmdbId!.isEmpty) &&
        (widget.fallbackUrl == null || widget.fallbackUrl!.isEmpty)) {
      _isLoading = false;
    } else {
      _loadImage();
    }
  }

  @override
  void didUpdateWidget(TMDBImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbId != widget.tmdbId ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      // Set loading to false immediately if we have no TMDB ID and no fallback URL
      // This ensures we show a placeholder right away
      if ((widget.tmdbId == null || widget.tmdbId!.isEmpty) &&
          (widget.fallbackUrl == null || widget.fallbackUrl!.isEmpty)) {
        setState(() {
          _isLoading = false;
          _imageUrl = null;
        });
      } else {
        _loadImage();
      }
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First try to get the TMDB image
      String? url;
      if (widget.tmdbId != null && widget.tmdbId!.isNotEmpty) {
        // Pass the fallback URL directly to the TMDB provider
        // This ensures it will return the fallback if TMDB has no image
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
      } else if (widget.fallbackUrl != null && widget.fallbackUrl!.isNotEmpty) {
        // If no TMDB ID but we have a fallback, use it
        url = widget.fallbackUrl;
      }

      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      // On error, try to use the fallback URL
      if (mounted) {
        setState(() {
          _imageUrl = widget.fallbackUrl;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use a SizedBox with the specified dimensions as the base
    // This ensures the widget always has a proper size for hit testing
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildContent();
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Show loading state
    if (_isLoading) {
      return const NetflixStyleLoading(
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Show placeholder if no image URL is available
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Image available - use Stack with loading background and image on top
    return Stack(
      children: [
        // Base loading layer - always visible until image loads
        const NetflixStyleLoading(
          width: double.infinity,
          height: double.infinity,
        ),

        // Image layer on top that fades in
        FadeInImage.memoryNetwork(
          placeholder: kTransparentImage, // Using transparent placeholder
          image: _imageUrl!,
          width: double.infinity,
          height: double.infinity,
          fit: widget.fit,
          fadeInDuration: const Duration(milliseconds: 300),
          fadeInCurve: Curves.easeIn,
          imageErrorBuilder: (context, error, stackTrace) {
            // If the image fails to load, try the fallback URL if it's different
            if (widget.fallbackUrl != null &&
                widget.fallbackUrl!.isNotEmpty &&
                _imageUrl != widget.fallbackUrl) {
              // Schedule a microtask to update the image URL to the fallback
              Future.microtask(() {
                if (mounted) {
                  setState(() {
                    _imageUrl = widget.fallbackUrl;
                  });
                }
              });
              // Show loading while we switch to fallback
              return const NetflixStyleLoading(
                width: double.infinity,
                height: double.infinity,
              );
            }
            // If fallback also fails or there is no fallback, show placeholder
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 40, // Fixed size icon
                ),
              ),
            );
          },
        ),
      ],
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
