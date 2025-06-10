import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../services/tmdb_image_provider.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with AutomaticKeepAliveClientMixin {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  String? _optimizedImageUrl;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOptimizedImage();
  }

  @override
  void didUpdateWidget(MovieCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.tmdbId != widget.movie.tmdbId) {
      _loadOptimizedImage();
    }
  }

  Future<void> _loadOptimizedImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load TMDB image URL in background
      final tmdbUrl =
          widget.movie.tmdbId != null
              ? await _imageProvider.getPosterUrl(
                widget.movie.tmdbId,
                widget.movie.coverUrl,
              )
              : widget.movie.coverUrl;

      if (mounted) {
        setState(() {
          _optimizedImageUrl = tmdbUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimizedImageUrl = widget.movie.coverUrl;
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 130,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.movie_filter_outlined,
          color: Colors.white24,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 130,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: SizedBox(
                width: 130,
                height: 190,
                child:
                    _optimizedImageUrl?.isNotEmpty == true
                        ? CachedNetworkImage(
                          imageUrl: _optimizedImageUrl!,
                          width: 130,
                          height: 190,
                          fit: BoxFit.cover,
                          memCacheWidth: 260, // 2x for retina displays
                          memCacheHeight: 380, // 2x for retina displays
                          maxWidthDiskCache: 260,
                          maxHeightDiskCache: 380,
                          placeholder: (context, url) => _buildPlaceholder(),
                          errorWidget:
                              (context, url, error) => _buildErrorWidget(),
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeInCurve: Curves.easeInOut,
                        )
                        : _buildPlaceholder(),
              ),
            ),
            const SizedBox(height: 6.0),
            SizedBox(
              width: 130,
              height: 20, // Fixed height for consistent layout
              child: Text(
                widget.movie.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
