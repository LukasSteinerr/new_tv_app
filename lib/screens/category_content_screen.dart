import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../services/playlist_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/tv_series_card.dart';
import 'movie_detail_screen.dart';
import 'tv_series_detail_screen.dart';

class CategoryContentScreen extends StatelessWidget {
  final Category category;
  final List<dynamic> items;
  final PlaylistService playlistService;

  const CategoryContentScreen({
    Key? key,
    required this.category,
    required this.items,
    required this.playlistService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body:
          items.isEmpty
              ? const Center(child: Text('No content in this category'))
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  if (item is Movie) {
                    return MovieCard(
                      movie: item,
                      onTap: () => _navigateToMovie(context, item),
                    );
                  } else if (item is TvSeries) {
                    return TvSeriesCard(
                      series: item,
                      onTap: () => _navigateToSeries(context, item),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
    );
  }

  void _navigateToMovie(BuildContext context, Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movie)),
    );
  }

  void _navigateToSeries(BuildContext context, TvSeries series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TvSeriesDetailScreen(
              series: series,
              playlistService: playlistService,
            ),
      ),
    );
  }
}
