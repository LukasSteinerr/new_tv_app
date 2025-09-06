import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../widgets/tmdb_image.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  _MovieCardState createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform:
              _isFocused
                  ? (Matrix4.identity()..scale(1.1))
                  : Matrix4.identity(),
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border:
                _isFocused ? Border.all(color: Colors.white, width: 2.0) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: TMDBImage(
              tmdbId: widget.movie.tmdbId,
              fallbackUrl: widget.movie.posterUrl ?? widget.movie.coverUrl,
              width: 150,
              height: 225,
              isMovie: true,
            ),
          ),
        ),
      ),
    );
  }
}
