import 'package:flutter/material.dart';
import '../models/tv_series.dart';
import '../widgets/tmdb_image.dart';

class TvSeriesCard extends StatefulWidget {
  final TvSeries series;
  final VoidCallback onTap;

  const TvSeriesCard({super.key, required this.series, required this.onTap});

  @override
  _TvSeriesCardState createState() => _TvSeriesCardState();
}

class _TvSeriesCardState extends State<TvSeriesCard> {
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
              tmdbId: widget.series.tmdbId,
              fallbackUrl: widget.series.coverUrl,
              width: 150,
              height: 225,
              isMovie: false,
            ),
          ),
        ),
      ),
    );
  }
}
