import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
// Will be used for BackdropFilter if we keep parts of old FeaturedContent
import 'dart:developer';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/playlist.dart';
import '../models/movie.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import '../widgets/content_carousel.dart';
import '../widgets/movie_card.dart';
import '../widgets/featured_content.dart';
import 'netflix_style_movie_detail_screen.dart';
import 'category_content_screen.dart';
import 'universal_video_player.dart';

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
  List<Movie> _featuredMovies =
      []; // Changed from _popularTmdbMovies to _featuredMovies
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
      // Get only movie categories from the playlist
      final allCategories = await widget.playlistService.getPlaylistCategories(
        widget.playlist.id,
      );
      final movieCategories =
          allCategories.where((category) => category.isMovie).toList();

      // Get all movies from the local playlist
      final categoryMoviesMap = <int, List<Movie>>{};
      for (final category in movieCategories) {
        final movies = await widget.playlistService.getCategoryMovies(
          category.id,
        );
        categoryMoviesMap[category.id] = movies;
      }

      // Get featured movies from the database
      final featuredMovies = await widget.playlistService.getFeaturedMovies(
        widget.playlist.id,
      );

      // Determine the primary featured movie (e.g., the first from the featured list)
      Movie? featuredMovieToShow;
      if (featuredMovies.isNotEmpty) {
        featuredMovieToShow = featuredMovies.first;
      } else {
        // Fallback to any local movie if no featured movies are found
        final allLocalMovies =
            categoryMoviesMap.values.expand((movies) => movies).toList();
        if (allLocalMovies.isNotEmpty) {
          featuredMovieToShow = allLocalMovies.firstWhere(
            (movie) => movie.tmdbId != null && movie.tmdbId!.isNotEmpty,
            orElse: () => allLocalMovies.first,
          );
        }
      }

      if (mounted) {
        setState(() {
          _featuredMovies = featuredMovies;
          _categories = movieCategories;
          _categoryMovies = categoryMoviesMap;
          _featuredMovie = featuredMovieToShow;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToMovie(Movie movie) {
    context.push('/movie-detail', extra: movie);
  }

  void _playMovie(Movie movie) async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all["Pro"] != null &&
          customerInfo.entitlements.all["Pro"]!.isActive) {
        // User is subscribed, play the movie
        _startPlayback(movie);
      } else {
        // User is not subscribed, show the paywall
        final paywallResult = await RevenueCatUI.presentPaywallIfNeeded("Pro");
        log("Paywall result: $paywallResult");
        if (paywallResult == PaywallResult.purchased) {
          _startPlayback(movie);
        }
      }
    } on PlatformException catch (e) {
      log("Paywall error: ${e.message}");
    }
  }

  void _startPlayback(Movie movie) {
    if (movie.streamUrl.isNotEmpty) {
      context.push('/video-player', extra: movie);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stream URL found for this movie.')),
      );
    }
  }

  void _navigateToSeeAll(Category category, List<Movie> movies) {
    context.push(
      '/category-content',
      extra: {
        'category': category,
        'items': movies,
        'playlistService': widget.playlistService,
      },
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
            onPressed: () => context.pop(),
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

    // Use popular TMDB movies for featured content
    if (_featuredMovies.isNotEmpty) {
      // Take up to 4 popular movies for the featured section
      final moviesToShowInFeatured = _featuredMovies.take(4).toList();

      for (var movie in moviesToShowInFeatured) {
        // Prefer featuredPosterUrl for featured content, then posterUrl, then coverUrl.
        String imageUrl =
            movie.featuredPosterUrl ?? movie.posterUrl ?? movie.coverUrl ?? '';
        featuredImageUrls.add(imageUrl);
        featuredPlayActions.add(() => _playMovie(movie));
        featuredDetailsActions.add(() => _navigateToMovie(movie));
      }
    }
    // Fallback if TMDB movies are not available but a _featuredMovie (from playlist) exists
    else if (_featuredMovie != null) {
      featuredImageUrls.add(_featuredMovie!.coverUrl ?? '');
      featuredPlayActions.add(() => _playMovie(_featuredMovie!));
      featuredDetailsActions.add(() => _navigateToMovie(_featuredMovie!));
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
          if (featuredImageUrls.isNotEmpty)
            SliverToBoxAdapter(
              child: FeaturedContent(
                key: ValueKey(
                  _featuredMovies.isNotEmpty
                      ? _featuredMovies.map((m) => m.tmdbId ?? m.id).join(',')
                      : _featuredMovie?.id ?? 'featured',
                ), // More robust key
                imageUrls: featuredImageUrls,
                // Pass movie titles if FeaturedContent supports displaying them
                // titles: _featuredMovies.take(6).map((m) => m.title).toList(),
                // Pass movie objects if FeaturedContent can use them directly
                // movies: _featuredMovies.take(6).toList(),
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
              ),
            ),
          // else if (_isLoading) // Avoid showing "No movies" during initial load if featured is also loading
          //   SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),

          // Category Carousels (from playlist)
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
