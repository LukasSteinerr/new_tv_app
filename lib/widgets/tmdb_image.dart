import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final bool isMovie;

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

class _TMDBImageState extends State<TMDBImage>
    with AutomaticKeepAliveClientMixin {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  String? _imageUrl;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(TMDBImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbId != widget.tmdbId ||
        oldWidget.fallbackUrl != widget.fallbackUrl ||
        oldWidget.isMovie != widget.isMovie) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (_isLoading) return;

    // Quick check: if no TMDB ID and no fallback, skip loading
    if ((widget.tmdbId == null || widget.tmdbId!.isEmpty) &&
        (widget.fallbackUrl == null || widget.fallbackUrl!.isEmpty)) {
      setState(() {
        _isLoading = false;
        _imageUrl = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
      } else {
        url = widget.fallbackUrl;
      }

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

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Icon(
          widget.isMovie ? Icons.movie : Icons.tv,
          color: Colors.white54,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(color: Colors.transparent, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    // Show loading state
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // Show placeholder if no image URL is available
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Use cached network image for better performance
    return CachedNetworkImage(
      imageUrl: _imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: (widget.width * 2).round(), // 2x for retina displays
      memCacheHeight: (widget.height * 2).round(), // 2x for retina displays
      maxWidthDiskCache: (widget.width * 2).round(),
      maxHeightDiskCache: (widget.height * 2).round(),
      placeholder: (context, url) => _buildLoadingWidget(),
      errorWidget: (context, url, error) {
        // Try fallback URL if available and different from current URL
        if (widget.fallbackUrl != null &&
            widget.fallbackUrl!.isNotEmpty &&
            _imageUrl != widget.fallbackUrl) {
          // Switch to fallback URL
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _imageUrl = widget.fallbackUrl;
              });
            }
          });
          return _buildLoadingWidget();
        }
        return _buildErrorWidget();
      },
      fadeInDuration: const Duration(milliseconds: 200),
      fadeInCurve: Curves.easeInOut,
    );
  }
}
