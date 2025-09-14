import 'package:flutter/material.dart';
import 'dart:async';

import './content_carousel.dart';
import './movie_card.dart';
import '../models/movie.dart';

class LazyLoadCarousel extends StatefulWidget {
  final String categoryName;
  final Future<List<Movie>> Function() movieFetcher;
  final void Function(Movie) onMovieTap;
  final void Function() onSeeAllTap;

  const LazyLoadCarousel({
    super.key,
    required this.categoryName,
    required this.movieFetcher,
    required this.onMovieTap,
    required this.onSeeAllTap,
  });

  @override
  State<LazyLoadCarousel> createState() => _LazyLoadCarouselState();
}

class _LazyLoadCarouselState extends State<LazyLoadCarousel> {
  List<Movie>? _movies;
  bool _isLoading = true;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // In a real-world scenario with a VisibilityDetector,
    // you'd trigger the load there. For this refactor, we'll
    // simplify and load on init, but the structure allows for
    // easy integration of visibility detection.
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final movies = await widget.movieFetcher();
      if (mounted) {
        setState(() {
          _movies = movies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Optionally handle error state in the UI
      print('Error loading movies for ${widget.categoryName}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSectionHeader(
        context,
        widget.categoryName,
        SizedBox(
          height: 230,
          child: Center(child: CircularProgressIndicator()),
        ),
        widget.onSeeAllTap,
      );
    }

    if (_movies == null || _movies!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionHeader(
      context,
      widget.categoryName,
      ContentCarousel<Movie>(
        items: _movies!,
        itemBuilder:
            (movie) =>
                MovieCard(movie: movie, onTap: () => widget.onMovieTap(movie)),
      ),
      widget.onSeeAllTap,
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    Widget content,
    VoidCallback onSeeAllTapped,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
        content,
      ],
    );
  }
}
