import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../services/playlist_service.dart';
import 'netflix_style_movie_detail_screen.dart';
import 'netflix_style_tv_series_detail_screen.dart';
import '../widgets/tmdb_image.dart';

class CategoryContentScreen extends StatefulWidget {
  final Category category;
  final PlaylistService playlistService;

  const CategoryContentScreen({
    super.key,
    required this.category,
    required this.playlistService,
  });

  @override
  _CategoryContentScreenState createState() => _CategoryContentScreenState();
}

class _CategoryContentScreenState extends State<CategoryContentScreen> {
  bool _isLoading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      List<dynamic> fetchedItems;
      if (widget.category.isMovie) {
        fetchedItems = await widget.playlistService.getCategoryMovies(
          widget.category.id,
        );
      } else if (widget.category.isSeries) {
        fetchedItems = await widget.playlistService.getCategoryTvSeries(
          widget.category.id,
        );
      } else {
        fetchedItems = [];
      }

      if (mounted) {
        setState(() {
          _items = fetchedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading content: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Colors.black,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(
                child: Text(
                  'No content in this category',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 2 / 3,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return GestureDetector(
                    onTap: () {
                      if (item is Movie) {
                        _navigateToMovie(context, item);
                      } else if (item is TvSeries) {
                        _navigateToSeries(context, item);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: TMDBImage(
                        tmdbId: item.tmdbId,
                        fallbackUrl: item.coverUrl,
                        width: 130,
                        height: 190,
                        isMovie: item is Movie,
                      ),
                    ),
                  );
                },
              ),
    );
  }

  void _navigateToMovie(BuildContext context, Movie movie) {
    context.push('/movie-detail', extra: movie);
  }

  void _navigateToSeries(BuildContext context, TvSeries series) {
    context.push(
      '/tv-series-detail',
      extra: {'series': series, 'playlistService': widget.playlistService},
    );
  }
}
