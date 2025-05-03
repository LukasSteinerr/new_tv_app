import 'package:flutter/material.dart';
import '../services/tmdb_image_provider.dart';
import 'fade_loading.dart';

class FeaturedContent extends StatefulWidget {
  final String title;
  final String? description;
  final String? tmdbId;
  final String? fallbackImageUrl;
  final VoidCallback onTap;
  final VoidCallback? onInfoTap;
  final VoidCallback? onMyListTap;
  final bool isMovie;
  final String? year;
  final String? rating;
  final List<Map<String, dynamic>>? additionalContent;
  // Add callbacks for additional content items
  final Function(int index)? onAdditionalContentTap;
  final Function(int index)? onAdditionalContentInfoTap;
  final Function(int index)? onAdditionalContentMyListTap;

  const FeaturedContent({
    super.key,
    required this.title,
    this.description,
    required this.tmdbId,
    this.fallbackImageUrl,
    required this.onTap,
    this.onInfoTap,
    this.onMyListTap,
    required this.isMovie,
    this.year,
    this.rating,
    this.additionalContent,
    this.onAdditionalContentTap,
    this.onAdditionalContentInfoTap,
    this.onAdditionalContentMyListTap,
  });

  @override
  State<FeaturedContent> createState() => _FeaturedContentState();
}

class _FeaturedContentState extends State<FeaturedContent> {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  String? _backdropUrl;
  bool _isLoading = true;
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _loadBackdropImage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
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
      // Use poster images for featured content instead of backdrop images
      String? posterUrl;

      if (widget.tmdbId != null && widget.tmdbId!.isNotEmpty) {
        posterUrl =
            widget.isMovie
                ? await _imageProvider.getPosterUrl(
                  widget.tmdbId,
                  widget.fallbackImageUrl,
                )
                : await _imageProvider.getTvPosterUrl(
                  widget.tmdbId,
                  widget.fallbackImageUrl,
                );
      }

      // If no poster available, try to use the fallback
      if (posterUrl == null && widget.fallbackImageUrl != null) {
        posterUrl = widget.fallbackImageUrl;
      }

      if (mounted) {
        setState(() {
          _backdropUrl =
              posterUrl; // We're still using the same variable name for compatibility
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Container(
                height: 530,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      Colors
                          .grey
                          .shade900, // Darker background for poster images
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child:
                    widget.additionalContent != null &&
                            widget.additionalContent!.isNotEmpty
                        ? _buildPageView()
                        : _buildSingleContent(),
              ),
              // Page indicators
              if (widget.additionalContent != null &&
                  widget.additionalContent!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPageNotifier,
                    builder: (context, currentPage, _) {
                      final totalPages = widget.additionalContent!.length + 1;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          totalPages,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  currentPage == index
                                      ? Colors.white
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          // Buttons positioned at bottom like Netflix
          Positioned(
            bottom:
                widget.additionalContent != null &&
                        widget.additionalContent!.isNotEmpty
                    ? 15
                    : -25,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentPage, _) {
                // Determine which callbacks to use based on current page
                final VoidCallback onPlayTap;
                final VoidCallback onMyListTap;

                if (currentPage == 0) {
                  // First item (main content)
                  onPlayTap = widget.onTap;
                  onMyListTap =
                      widget.onMyListTap ?? widget.onInfoTap ?? widget.onTap;
                } else if (widget.additionalContent != null &&
                    currentPage - 1 < widget.additionalContent!.length) {
                  // Additional content items
                  final additionalIndex = currentPage - 1;
                  onPlayTap = () {
                    if (widget.onAdditionalContentTap != null) {
                      widget.onAdditionalContentTap!(additionalIndex);
                    } else {
                      widget.onTap();
                    }
                  };

                  onMyListTap = () {
                    if (widget.onAdditionalContentMyListTap != null) {
                      widget.onAdditionalContentMyListTap!(additionalIndex);
                    } else if (widget.onAdditionalContentInfoTap != null) {
                      widget.onAdditionalContentInfoTap!(additionalIndex);
                    } else if (widget.onAdditionalContentTap != null) {
                      widget.onAdditionalContentTap!(additionalIndex);
                    } else {
                      if (widget.onMyListTap != null) {
                        widget.onMyListTap!();
                      } else if (widget.onInfoTap != null) {
                        widget.onInfoTap!();
                      } else {
                        widget.onTap();
                      }
                    }
                  };
                } else {
                  // Fallback
                  onPlayTap = widget.onTap;
                  onMyListTap =
                      widget.onMyListTap ?? widget.onInfoTap ?? widget.onTap;
                }

                return SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Play button
                      Container(
                        height: 50,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onPlayTap,
                            borderRadius: BorderRadius.circular(5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.black,
                                  size: 30,
                                ),
                                Text(
                                  "Play",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      // My List button
                      Container(
                        height: 50,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onMyListTap,
                            borderRadius: BorderRadius.circular(5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 30),
                                Text(
                                  "My List",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
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
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: Colors.grey.shade900,
                          child: Center(
                            child: Icon(
                              widget.isMovie ? Icons.movie : Icons.tv,
                              size: 80,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                  ),
                ],
              )
              : Container(
                color: Colors.grey.shade900,
                child: Center(
                  child: Icon(
                    widget.isMovie ? Icons.movie : Icons.tv,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),

          // Gradient overlay for better text visibility - Netflix style
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(77), // 0.3 opacity
                    Colors.black.withAlpha(128), // 0.5 opacity
                    Colors.black.withAlpha(204), // 0.8 opacity
                  ],
                  stops: const [0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Content info - positioned at top (title removed)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.year != null || widget.rating != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        if (widget.year != null)
                          Text(
                            widget.year!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black,
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                          ),
                        if (widget.year != null && widget.rating != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              "•",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black,
                                    offset: Offset(2.0, 2.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (widget.rating != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(128), // 0.5 opacity
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.rating!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to load poster image for an item
  Future<String?> _loadItemBackdrop(Map<String, dynamic> item) async {
    final String? tmdbId = item['tmdbId'];
    final bool isMovie = item['isMovie'] ?? widget.isMovie;
    final String? fallbackUrl = item['fallbackImageUrl'];

    if (tmdbId == null || tmdbId.isEmpty) {
      return item['backdropUrl'] ?? fallbackUrl;
    }

    try {
      final posterUrl =
          isMovie
              ? await _imageProvider.getPosterUrl(tmdbId, fallbackUrl)
              : await _imageProvider.getTvPosterUrl(tmdbId, fallbackUrl);

      return posterUrl;
    } catch (e) {
      return fallbackUrl;
    }
  }

  // Helper method to build fallback image
  Widget _buildFallbackImage(Map<String, dynamic> item) {
    final bool isMovie = item['isMovie'] ?? widget.isMovie;

    if (item['fallbackImageUrl'] != null) {
      return Image.network(
        item['fallbackImageUrl'],
        fit: BoxFit.contain,
        errorBuilder:
            (_, __, ___) => Container(
              color: Colors.grey.shade900,
              child: Center(
                child: Icon(
                  isMovie ? Icons.movie : Icons.tv,
                  size: 80,
                  color: Colors.white54,
                ),
              ),
            ),
      );
    } else {
      return Container(
        color: Colors.grey.shade900,
        child: Center(
          child: Icon(
            isMovie ? Icons.movie : Icons.tv,
            size: 80,
            color: Colors.white54,
          ),
        ),
      );
    }
  }

  Widget _buildPageView() {
    // Create a copy of the main content with the current backdrop URL
    final Map<String, dynamic> mainContent = {
      'title': widget.title,
      'description': widget.description,
      'backdropUrl': _backdropUrl,
      'fallbackImageUrl': widget.fallbackImageUrl,
      'year': widget.year,
      'rating': widget.rating,
      'isMovie': widget.isMovie,
      'tmdbId': widget.tmdbId, // Include TMDB ID for potential image loading
    };

    // Combine main content with additional content
    final List<Map<String, dynamic>> allContent = [
      mainContent,
      ...widget.additionalContent!,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: PageView.builder(
        controller: _pageController,
        itemCount: allContent.length,
        onPageChanged: (index) {
          _currentPageNotifier.value = index;
        },
        itemBuilder: (context, index) {
          final item = allContent[index];
          return GestureDetector(
            onTap: () {
              final additionalIndex = index - 1;
              if (index == 0) {
                widget.onTap();
              } else if (widget.onAdditionalContentTap != null) {
                widget.onAdditionalContentTap!(additionalIndex);
              } else {
                widget.onTap();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image - load backdrop for each item
                FutureBuilder<String?>(
                  future: _loadItemBackdrop(item),
                  builder: (context, snapshot) {
                    // If we have a backdrop URL from the snapshot, use it
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data != null) {
                      return Image.network(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          // On error, try fallback
                          return _buildFallbackImage(item);
                        },
                      );
                    }
                    // If we already have a backdrop URL in the item, use it
                    else if (item['backdropUrl'] != null) {
                      return Image.network(
                        item['backdropUrl'],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          // On error, try fallback
                          return _buildFallbackImage(item);
                        },
                      );
                    }
                    // Otherwise use fallback or placeholder
                    else {
                      return _buildFallbackImage(item);
                    }
                  },
                ),

                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(77), // 0.3 opacity
                          Colors.black.withAlpha(128), // 0.5 opacity
                          Colors.black.withAlpha(204), // 0.8 opacity
                        ],
                        stops: const [0.3, 0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content info (title removed)
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['year'] != null || item['rating'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              if (item['year'] != null)
                                Text(
                                  item['year'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black,
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['year'] != null &&
                                  item['rating'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    "•",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Colors.black,
                                          offset: Offset(2.0, 2.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (item['rating'] != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(
                                      128,
                                    ), // 0.5 opacity
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['rating'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
