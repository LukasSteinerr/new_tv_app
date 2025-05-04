import 'package:flutter/material.dart';
import 'dart:ui';
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

  const MoviesScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
  });

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  List<Category> _categories = [];
  Map<int, List<Movie>> _categoryMovies = {};
  bool _isLoading = true;
  Movie? _featuredMovie;

  @override
  void initState() {
    super.initState();
    _loadData();
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
          orElse: () => allMovies.first,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return const Center(child: Text('No movies found'));
    }

    return Scaffold(
      // Remove the standard app bar
      extendBodyBehindAppBar: true, // Allow content to go behind app bar
      body: Stack(
        children: [
          // Main content
          ListView(
            padding: const EdgeInsets.only(
              top: 70,
            ), // Add padding for the app bar
            children: [
              // Featured Movie - Netflix style
              if (_featuredMovie != null)
                FeaturedContent(
                  title: _featuredMovie!.name,
                  description: _featuredMovie!.description,
                  tmdbId: _featuredMovie!.tmdbId,
                  fallbackImageUrl: _featuredMovie!.coverUrl,
                  year: _featuredMovie!.year,
                  rating: _featuredMovie!.rating,
                  isMovie: true,
                  onTap: () => _navigateToMovie(_featuredMovie!),
                  onInfoTap: () => _navigateToMovie(_featuredMovie!),
                  onMyListTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added to My List: ${_featuredMovie!.name}',
                        ),
                      ),
                    );
                  },
                  // Optional: Add more movies for PageView
                  additionalContent:
                      _categoryMovies.values
                          .expand((movies) => movies)
                          .where(
                            (movie) =>
                                movie.id != _featuredMovie!.id &&
                                movie.tmdbId != null &&
                                movie.tmdbId!.isNotEmpty,
                          )
                          .take(5)
                          .map(
                            (movie) => {
                              'title': movie.name,
                              'description': movie.description,
                              'backdropUrl':
                                  null, // Will be loaded by TMDB service
                              'fallbackImageUrl': movie.coverUrl,
                              'year': movie.year,
                              'rating': movie.rating,
                              'isMovie': true,
                              'id':
                                  movie
                                      .id, // Store the ID to identify the movie later
                              'tmdbId':
                                  movie
                                      .tmdbId, // Include TMDB ID for image loading
                            },
                          )
                          .toList(),
                  // Add callbacks for additional content
                  onAdditionalContentTap: (index) {
                    final additionalMovies =
                        _categoryMovies.values
                            .expand((movies) => movies)
                            .where(
                              (movie) =>
                                  movie.id != _featuredMovie!.id &&
                                  movie.tmdbId != null &&
                                  movie.tmdbId!.isNotEmpty,
                            )
                            .take(5)
                            .toList();

                    if (index < additionalMovies.length) {
                      _navigateToMovie(additionalMovies[index]);
                    }
                  },
                  onAdditionalContentInfoTap: (index) {
                    final additionalMovies =
                        _categoryMovies.values
                            .expand((movies) => movies)
                            .where(
                              (movie) =>
                                  movie.id != _featuredMovie!.id &&
                                  movie.tmdbId != null &&
                                  movie.tmdbId!.isNotEmpty,
                            )
                            .take(5)
                            .toList();

                    if (index < additionalMovies.length) {
                      _navigateToMovie(additionalMovies[index]);
                    }
                  },
                  onAdditionalContentMyListTap: (index) {
                    final additionalMovies =
                        _categoryMovies.values
                            .expand((movies) => movies)
                            .where(
                              (movie) =>
                                  movie.id != _featuredMovie!.id &&
                                  movie.tmdbId != null &&
                                  movie.tmdbId!.isNotEmpty,
                            )
                            .take(5)
                            .toList();

                    if (index < additionalMovies.length) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added to My List: ${additionalMovies[index].name}',
                          ),
                        ),
                      );
                    }
                  },
                ),

              // Category Carousels
              ..._categories.map((category) {
                final movies = _categoryMovies[category.id] ?? [];
                if (movies.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ContentCarousel<Movie>(
                  title: category.name,
                  items: movies,
                  itemBuilder:
                      (movie) => MovieCard(
                        movie: movie,
                        onTap: () => _navigateToMovie(movie),
                      ),
                  onSeeAllPressed: () => _navigateToSeeAll(category, movies),
                );
              }),

              // Add some padding at the bottom
              const SizedBox(height: 20),
            ],
          ),

          // Custom app bar with blur effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Back button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          // Title - Show playlist name
                          Text(
                            widget.playlist.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          // Search button
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              // Add search functionality here
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
