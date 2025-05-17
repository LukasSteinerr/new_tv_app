import 'package:flutter/material.dart';
import 'dart:ui'; // Will be used for BackdropFilter if we keep parts of old FeaturedContent
import '../models/playlist.dart';
import '../models/movie.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import '../widgets/content_carousel.dart';
import '../widgets/movie_card.dart';
import '../widgets/featured_content.dart';
import 'netflix_style_movie_detail_screen.dart';
import 'category_content_screen.dart';

class MoviesScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;
  final Function(double scrollOffset)? onScrollUpdate; // Add callback

  const MoviesScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
    this.onScrollUpdate, // Add callback parameter
  });

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  List<Category> _categories = [];
  Map<int, List<Movie>> _categoryMovies = {};
  bool _isLoading = true;
  Movie? _featuredMovie;
  late ScrollController _scrollController;
  // _appBarOpacity is now managed by the parent, remove from here
  // double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(
      _notifyScrollUpdate,
    ); // Use a dedicated method
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_notifyScrollUpdate); // Remove listener
    _scrollController.dispose();
    super.dispose();
  }

  void _notifyScrollUpdate() {
    if (widget.onScrollUpdate != null) {
      widget.onScrollUpdate!(_scrollController.offset); // Call the callback
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get only movie categories
      final allCategories = await widget.playlistService.getPlaylistCategories(
        widget.playlist.id,
      );
      final movieCategories =
          allCategories.where((category) => category.isMovie).toList();

      // Get movies for each category
      final categoryMoviesMap = <int, List<Movie>>{};
      List<Movie> allMovies = [];

      for (final category in movieCategories) {
        final movies = await widget.playlistService.getCategoryMovies(
          category.id,
        );
        categoryMoviesMap[category.id] = movies;
        allMovies.addAll(movies);
      }

      // Select a featured movie (one with a TMDB ID if possible)
      Movie? featuredMovie;
      if (allMovies.isNotEmpty) {
        // First try to find a movie with a TMDB ID
        featuredMovie = allMovies.firstWhere(
          (movie) => movie.tmdbId != null && movie.tmdbId!.isNotEmpty,
          orElse: () => allMovies.first, // Fallback to the first movie
        );
      }

      if (mounted) {
        setState(() {
          _categories = movieCategories;
          _categoryMovies = categoryMoviesMap;
          _featuredMovie = featuredMovie;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading movies: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToMovie(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetflixStyleMovieDetailScreen(movie: movie),
      ),
    );
  }

  void _navigateToSeeAll(Category category, List<Movie> movies) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CategoryContentScreen(
              category: category,
              items: movies,
              playlistService: widget.playlistService,
            ),
      ),
    );
  }

  // Copied and adapted from UI/lib/home_screen.dart
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onSeeAllTapped,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 24.0,
          left: 16.0,
          right: 16.0,
          bottom: 12.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onSeeAllTapped,
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_categories.isEmpty && _featuredMovie == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.playlist.name,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text('No movies found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    List<String> featuredImageUrls = [];
    List<Function()> featuredPlayActions = [];
    List<Function()> featuredDetailsActions = [];

    if (_featuredMovie != null) {
      featuredImageUrls.add(
        _featuredMovie!.coverUrl ??
            '', // Use coverUrl, fallback to empty string
      );
      featuredPlayActions.add(
        () => _navigateToMovie(_featuredMovie!),
      ); // Or play action
      featuredDetailsActions.add(() => _navigateToMovie(_featuredMovie!));

      // Add additional content for PageView from other movies
      final allOtherMovies =
          _categoryMovies.values
              .expand((movies) => movies)
              .where(
                (movie) =>
                    movie.id != _featuredMovie!.id &&
                    (movie.coverUrl != null &&
                        movie
                            .coverUrl!
                            .isNotEmpty), // Ensure coverUrl is not null or empty
              )
              .take(5) // Limit to 5 additional items for the featured section
              .toList();

      for (var movie in allOtherMovies) {
        featuredImageUrls.add(
          movie.coverUrl ?? '',
        ); // Use coverUrl, fallback to empty string
        featuredPlayActions.add(() => _navigateToMovie(movie));
        featuredDetailsActions.add(() => _navigateToMovie(movie));
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      // AppBar is removed from here and will be in the parent XtreamPlaylistScreen
      body: CustomScrollView(
        controller:
            _scrollController, // Keep controller for opacity calculation
        slivers: <Widget>[
          // Remove top padding, content should go behind the parent AppBar
          // Featured Content - to be replaced with a new/modified FeaturedContent widget
          if (featuredImageUrls.isNotEmpty)
            SliverToBoxAdapter(
              child: FeaturedContent(
                // This will be the new/modified FeaturedContent
                key: ValueKey(
                  _featuredMovie?.id ?? 'featured',
                ), // Ensure widget rebuilds if featured movie changes
                imageUrls: featuredImageUrls,
                onPlayTapped: (index) {
                  if (index < featuredPlayActions.length) {
                    featuredPlayActions[index]();
                  }
                },
                onDetailsTapped: (index) {
                  if (index < featuredDetailsActions.length) {
                    featuredDetailsActions[index]();
                  }
                },
                // We'll need to pass movie details for the "Details" button if it's generic
                // For now, the actions above handle navigation.
              ),
            ),

          // Category Carousels
          ..._categories.expand((category) {
            final movies = _categoryMovies[category.id] ?? [];
            if (movies.isEmpty) {
              return [const SliverToBoxAdapter(child: SizedBox.shrink())];
            }

            return [
              _buildSectionHeader(
                context,
                category.name,
                () => _navigateToSeeAll(category, movies),
              ),
              SliverToBoxAdapter(
                child: ContentCarousel<Movie>(
                  // This will be the modified ContentCarousel
                  items: movies,
                  itemBuilder:
                      (movie) => MovieCard(
                        // This will be the modified MovieCard
                        movie: movie,
                        onTap: () => _navigateToMovie(movie),
                      ),
                ),
              ),
            ];
          }),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ), // Bottom padding
        ],
      ),
    );
  }
}
