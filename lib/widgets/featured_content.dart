import 'package:flutter/material.dart';
import '../services/tmdb_image_provider.dart';
import '../constants/app_theme.dart';
import 'fade_loading.dart';

class FeaturedContent extends StatefulWidget {
  final String title;
  final String? description;
  final String? tmdbId;
  final String? fallbackImageUrl;
  final VoidCallback onTap;
  final bool isMovie;
  final String? year;
  final String? rating;

  const FeaturedContent({
    super.key,
    required this.title,
    this.description,
    required this.tmdbId,
    this.fallbackImageUrl,
    required this.onTap,
    required this.isMovie,
    this.year,
    this.rating,
  });

  @override
  State<FeaturedContent> createState() => _FeaturedContentState();
}

class _FeaturedContentState extends State<FeaturedContent> {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  String? _backdropUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackdropImage();
  }

  @override
  void didUpdateWidget(FeaturedContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbId != widget.tmdbId) {
      _loadBackdropImage();
    }
  }

  Future<void> _loadBackdropImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backdropUrl = widget.isMovie
          ? await _imageProvider.getBackdropUrl(widget.tmdbId)
          : await _imageProvider.getTvBackdropUrl(widget.tmdbId);

      if (mounted) {
        setState(() {
          _backdropUrl = backdropUrl ?? widget.fallbackImageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backdropUrl = widget.fallbackImageUrl;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 530, // Exact height from imported project
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20), // Rounded corners like in imported project
        border: Border.all(color: Colors.black), // Black border
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Match container's border radius
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop image with loading state
            _isLoading
                ? const FadeLoading(
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: 0,
                  )
                : _backdropUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          // Loading placeholder
                          const FadeLoading(
                            height: double.infinity,
                            width: double.infinity,
                            borderRadius: 0,
                          ),
                          // Actual image
                          Image.network(
                            _backdropUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[900],
                              child: Icon(
                                widget.isMovie ? Icons.movie : Icons.tv,
                                size: 80,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: Icon(
                          widget.isMovie ? Icons.movie : Icons.tv,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),

            // Gradient overlay for better text visibility - matches imported project
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(100), // Lighter at top
                      Colors.black.withAlpha(200), // Darker at bottom
                    ],
                    stops: const [0.5, 0.8, 1.0], // Starts gradient lower down
                  ),
                ),
              ),
            ),

            // Content info - positioned at bottom like in imported project
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24.0), // Exact padding from imported project
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16), // Exact spacing from imported project

                    // Buttons row - matches imported project
                    Row(
                      children: [
                        // Play button
                        ElevatedButton.icon(
                          onPressed: widget.onTap,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.netflixRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info button
                        ElevatedButton.icon(
                          onPressed: widget.onTap,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Info'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.netflixDarkGrey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
