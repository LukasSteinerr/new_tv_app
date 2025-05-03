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
    _loadImage();
  }

  @override
  void didUpdateWidget(TMDBImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbId != widget.tmdbId ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url =
          widget.isMovie
              ? await _imageProvider.getPosterUrl(
                widget.tmdbId,
                widget.fallbackUrl,
              )
              : await _imageProvider.getTvPosterUrl(
                widget.tmdbId,
                widget.fallbackUrl,
              );

      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
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
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const NetflixStyleLoading(
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Icon(
            widget.isMovie ? Icons.movie : Icons.tv,
            color: Colors.white54,
            size: widget.width / 2,
          ),
        ),
      );
    }

    // Use Stack with NetflixStyleLoading as base and FadeInImage on top
    // This ensures we always see the grey loading background until the image is fully loaded
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
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          fadeInDuration: const Duration(milliseconds: 300),
          fadeInCurve: Curves.easeIn,
          imageErrorBuilder:
              widget.errorBuilder ??
              (context, error, stackTrace) {
                return SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: Center(
                    child: Icon(
                      widget.isMovie ? Icons.movie : Icons.tv,
                      color: Colors.white54,
                      size: widget.width / 2,
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }
}
