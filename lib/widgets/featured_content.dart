import 'package:flutter/material.dart';
// Assuming Movie model might be needed if we pass full details later,
// but for now, callbacks are index-based.
// import '../models/movie.dart';

class FeaturedContent extends StatefulWidget {
  final List<String> imageUrls;
  final Function(int index) onPlayTapped;
  final Function(int index) onDetailsTapped;
  // Optional: if you want to pass titles or other data per featured item for the buttons
  // final List<String>? titles;

  const FeaturedContent({
    super.key,
    required this.imageUrls,
    required this.onPlayTapped,
    required this.onDetailsTapped,
    // this.titles,
  });

  @override
  State<FeaturedContent> createState() => _FeaturedContentState();
}

class _FeaturedContentState extends State<FeaturedContent> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < widget.imageUrls.length; i++) {
      indicators.add(
        Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _currentPage == i
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: indicators,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink(); // Don't build if there are no images
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (int page) {
              if (mounted) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
            itemBuilder: (context, index) {
              // Ensure URL is not empty before trying to load
              if (widget.imageUrls[index].isEmpty) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white24,
                      size: 100,
                    ),
                  ),
                );
              }
              return Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.movie_creation_outlined, // Or Icons.error
                          color: Colors.white24,
                          size: 100,
                        ),
                      ),
                    ),
              );
            },
          ),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                    Colors.black.withOpacity(0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: _buildPageIndicator(),
          ),
          Positioned(
            bottom: 30, // As per reference UI
            left: 20,
            right: 20,
            child: Column(
              // Column to ensure buttons are centered if they wrap (though unlikely here)
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120.0, // As per reference UI
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onPlayTapped(_currentPage);
                        },
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Play'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20, // Adjusted to match reference
                            vertical: 8, // Adjusted to match reference
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // As per reference
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15), // As per reference UI
                    SizedBox(
                      width: 120.0, // As per reference UI
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onDetailsTapped(_currentPage);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20, // Adjusted to match reference
                            vertical: 8, // Adjusted to match reference
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // As per reference
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          elevation: 2, // As per reference
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        child: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
