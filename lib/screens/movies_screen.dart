import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/movie.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import '../widgets/content_carousel.dart';
import '../widgets/movie_card.dart';
import 'movie_player_screen.dart';

class MoviesScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const MoviesScreen({
    Key? key,
    required this.playlistService,
    required this.playlist,
  }) : super(key: key);

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  List<Category> _categories = [];
  Map<int, List<Movie>> _categoryMovies = {};
  bool _isLoading = true;

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
      for (final category in movieCategories) {
        final movies = await widget.playlistService.getCategoryMovies(
          category.id,
        );
        categoryMoviesMap[category.id] = movies;
      }

      if (mounted) {
        setState(() {
          _categories = movieCategories;
          _categoryMovies = categoryMoviesMap;
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
      MaterialPageRoute(builder: (context) => MoviePlayerScreen(movie: movie)),
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

    return ListView(
      children: [
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
          );
        }),

        // Add some padding at the bottom
        const SizedBox(height: 20),
      ],
    );
  }
}
