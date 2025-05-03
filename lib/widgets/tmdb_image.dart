import 'package:flutter/material.dart';
import '../services/tmdb_image_provider.dart';

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
    if (oldWidget.tmdbId != widget.tmdbId || oldWidget.fallbackUrl != widget.fallbackUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = widget.isMovie
          ? await _imageProvider.getPosterUrl(widget.tmdbId, widget.fallbackUrl)
          : await _imageProvider.getTvPosterUrl(widget.tmdbId, widget.fallbackUrl);

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
        child: const Center(
          child: CircularProgressIndicator(),
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
            size: widget.width / 2,
          ),
        ),
      );
    }

    return Image.network(
      _imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: widget.loadingBuilder ??
          (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
      errorBuilder: widget.errorBuilder ??
          (context, error, stackTrace) {
            return SizedBox(
              width: widget.width,
              height: widget.height,
              child: Center(
                child: Icon(
                  widget.isMovie ? Icons.movie : Icons.tv,
                  size: widget.width / 2,
                ),
              ),
            );
          },
    );
  }
}
