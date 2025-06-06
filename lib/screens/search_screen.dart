import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../services/objectbox_service.dart';
import 'netflix_style_movie_detail_screen.dart';
import 'netflix_style_tv_series_detail_screen.dart';
import '../services/playlist_service.dart';

class SearchScreen extends SearchDelegate {
  final ObjectBoxService objectBoxService;
  final PlaylistService playlistService;

  SearchScreen({required this.objectBoxService, required this.playlistService});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white)),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(color: Colors.black);
    }

    final movies =
        objectBoxService
            .getAllMovies()
            .where(
              (movie) => movie.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    final series =
        objectBoxService
            .getAllTvSeries()
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

    final results = [...movies, ...series];

    return Container(
      color: Colors.black,
      child: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 2 / 3,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final item = results[index];
          if (item is Movie) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NetflixStyleMovieDetailScreen(movie: item),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  item.posterUrl ?? item.coverUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.white),
                    );
                  },
                ),
              ),
            );
          } else if (item is TvSeries) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NetflixStyleTvSeriesDetailScreen(
                          series: item,
                          playlistService: playlistService,
                        ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  item.coverUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.tv, color: Colors.white),
                    );
                  },
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(color: Colors.black);
    }

    final movies =
        objectBoxService
            .getAllMovies()
            .where(
              (movie) => movie.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    final series =
        objectBoxService
            .getAllTvSeries()
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

    final results = [...movies, ...series];

    return Container(
      color: Colors.black,
      child: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 2 / 3,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final item = results[index];
          if (item is Movie) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NetflixStyleMovieDetailScreen(movie: item),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  item.posterUrl ?? item.coverUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.white),
                    );
                  },
                ),
              ),
            );
          } else if (item is TvSeries) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NetflixStyleTvSeriesDetailScreen(
                          series: item,
                          playlistService: playlistService,
                        ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  item.coverUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.tv, color: Colors.white),
                    );
                  },
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
