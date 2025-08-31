import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../services/objectbox_service.dart';
import 'netflix_style_movie_detail_screen.dart';
import 'netflix_style_tv_series_detail_screen.dart';
import '../services/playlist_service.dart';
import '../widgets/tmdb_image.dart';

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
                context.push('/movie-detail', extra: item);
              },
              child: Column(
                children: [
                  Expanded(
                    child: TMDBImage(
                      tmdbId: item.tmdbId,
                      fallbackUrl: item.coverUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      isMovie: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          } else if (item is TvSeries) {
            return GestureDetector(
              onTap: () {
                context.push(
                  '/tv-series-detail',
                  extra: {'series': item, 'playlistService': playlistService},
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: TMDBImage(
                      tmdbId: item.tmdbId,
                      fallbackUrl: item.coverUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      isMovie: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                context.push('/movie-detail', extra: item);
              },
              child: Column(
                children: [
                  Expanded(
                    child: TMDBImage(
                      tmdbId: item.tmdbId,
                      fallbackUrl: item.coverUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      isMovie: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          } else if (item is TvSeries) {
            return GestureDetector(
              onTap: () {
                context.push(
                  '/tv-series-detail',
                  extra: {'series': item, 'playlistService': playlistService},
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: TMDBImage(
                      tmdbId: item.tmdbId,
                      fallbackUrl: item.coverUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      isMovie: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
