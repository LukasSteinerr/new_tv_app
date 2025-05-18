import 'package:flutter/material.dart';
// Will be used for BackdropFilter if we keep parts of old FeaturedContent
import '../models/playlist.dart';
import '../models/movie.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import '../services/tmdb_service.dart'; // Added TMDB Service import
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
  List<Movie> _popularTmdbMovies = []; // Added for TMDB popular movies
  bool _isLoading = true;
  Movie?
  _featuredMovie; // This might still be used or could be replaced by the first TMDB movie
  late ScrollController _scrollController;
  late TMDBService _tmdbService; // Corrected class name TMDBService

  // _appBarOpacity is now managed by the parent, remove from here
  // double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _tmdbService = TMDBService(); // Corrected class name TMDBService
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
      // Fetch popular TMDB movies (these are Movie objects from TMDB API)
      final popularTmdbApiMovies = await _tmdbService.getPopularMovies();

      // Get only movie categories from the playlist
      final allCategories = await widget.playlistService.getPlaylistCategories(
        widget.playlist.id,
      );
      final movieCategories =
          allCategories.where((category) => category.isMovie).toList();

      // Get all movies from the local playlist and their TMDB IDs
      final categoryMoviesMap = <int, List<Movie>>{};
      List<Movie> allLocalMovies = [];
      for (final category in movieCategories) {
        final movies = await widget.playlistService.getCategoryMovies(
          category.id,
        );
        categoryMoviesMap[category.id] = movies;
        allLocalMovies.addAll(movies);
      }

      // Create a map of local movies by their TMDB ID for easy lookup
      Map<String, Movie> localMoviesByTmdbId = {
        for (var movie in allLocalMovies)
          if (movie.tmdbId != null && movie.tmdbId!.isNotEmpty)
            movie.tmdbId!: movie,
      };

      // Iterate through popular TMDB movies. If a popular movie's TMDB ID is in our local map,
      // add the *local* movie object (which has the correct streamUrl) to the list of movies to feature.
      // Update the local movie's details (like image URLs, description, rating) with fresh data from TMDB.
      List<Movie> moviesToFeature = [];
      for (var tmdbApiMovie in popularTmdbApiMovies) {
        if (localMoviesByTmdbId.containsKey(tmdbApiMovie.tmdbId)) {
          Movie localVersion = localMoviesByTmdbId[tmdbApiMovie.tmdbId]!;

          // Update localVersion with fresh TMDB data for display purposes,
          // while retaining its core identity and streamUrl.
          localVersion.name =
              tmdbApiMovie.name; // TMDB 'title' is mapped to 'name'
          localVersion.description =
              tmdbApiMovie.description ?? localVersion.description;
          localVersion.posterUrl =
              tmdbApiMovie.posterUrl ?? localVersion.posterUrl;
          localVersion.backdropUrl =
              tmdbApiMovie.backdropUrl ?? localVersion.backdropUrl;
          localVersion.rating = tmdbApiMovie.rating ?? localVersion.rating;
          localVersion.year = tmdbApiMovie.year ?? localVersion.year;
          // tmdbId is already matched. streamUrl is preserved from localVersion.

          moviesToFeature.add(localVersion);
        }
      }

      // Determine the primary featured movie (e.g., the first from the feature list)
      Movie? featuredMovieToShow;
      if (moviesToFeature.isNotEmpty) {
        featuredMovieToShow = moviesToFeature.first;
      } else if (allLocalMovies.isNotEmpty) {
        // Fallback to any local movie if no popular local movies are found
        featuredMovieToShow = allLocalMovies.firstWhere(
          (movie) => movie.tmdbId != null && movie.tmdbId!.isNotEmpty,
          orElse:
              () =>
                  allLocalMovies
                      .first, // Fallback to the very first local movie
        );
      }

      if (mounted) {
        setState(() {
          _popularTmdbMovies =
              moviesToFeature; // This list now contains local Movie objects with updated TMDB info
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

    // Use popular TMDB movies for featured content
    if (_popularTmdbMovies.isNotEmpty) {
      // Take up to 4 popular movies for the featured section
      final moviesToShowInFeatured = _popularTmdbMovies.take(4).toList();

      for (var movie in moviesToShowInFeatured) {
        // Prefer poster for featured content, then coverUrl. Avoid backdrop here.
        String imageUrl =
            movie.posterUrl ??
            movie.coverUrl ??
            ''; // Use poster, then cover, then empty
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          // Assuming TmdbService provides a method to get full image URL
          // or TmdbImageProvider.getFullImageUrl exists and is static/accessible
          // For now, let's assume the URL is already complete or TmdbImage widget handles it.
          // If not, this needs adjustment: e.g., imageUrl = _tmdbService.getFullBackdropPath(movie.backdropPath);
        }
        featuredImageUrls.add(imageUrl);
        featuredPlayActions.add(() => _navigateToMovie(movie));
        featuredDetailsActions.add(() => _navigateToMovie(movie));
      }
    }
    // Fallback if TMDB movies are not available but a _featuredMovie (from playlist) exists
    else if (_featuredMovie != null) {
      featuredImageUrls.add(_featuredMovie!.coverUrl ?? '');
      featuredPlayActions.add(() => _navigateToMovie(_featuredMovie!));
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
                  _popularTmdbMovies.isNotEmpty
                      ? _popularTmdbMovies
                          .map((m) => m.tmdbId ?? m.id)
                          .join(',')
                      : _featuredMovie?.id ?? 'featured',
                ), // More robust key
                imageUrls: featuredImageUrls,
                // Pass movie titles if FeaturedContent supports displaying them
                // titles: _popularTmdbMovies.take(6).map((m) => m.title).toList(),
                // Pass movie objects if FeaturedContent can use them directly
                // movies: _popularTmdbMovies.take(6).toList(),
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
