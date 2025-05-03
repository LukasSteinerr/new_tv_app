import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_image_provider.dart';
import 'movie_player_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  bool _isLoading = true;
  String? _posterUrl;
  String? _backdropUrl;

  @override
  void initState() {
    super.initState();
    _loadTMDBData();
  }

  Future<void> _loadTMDBData() async {
    if (widget.movie.tmdbId != null && widget.movie.tmdbId!.isNotEmpty) {
      try {
        // Load poster and backdrop in parallel
        final posterFuture = _imageProvider.getPosterUrl(
          widget.movie.tmdbId,
          widget.movie.coverUrl,
        );
        final backdropFuture = _imageProvider.getBackdropUrl(
          widget.movie.tmdbId,
        );

        final results = await Future.wait([posterFuture, backdropFuture]);

        if (mounted) {
          setState(() {
            _posterUrl = results[0]; // Poster URL
            _backdropUrl = results[1]; // Backdrop URL
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _posterUrl = widget.movie.coverUrl;
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _posterUrl = widget.movie.coverUrl;
        _isLoading = false;
      });
    }
  }

  void _playMovie() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoviePlayerScreen(movie: widget.movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  // Backdrop and app bar
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(widget.movie.name),
                      background:
                          _backdropUrl != null
                              ? Image.network(
                                _backdropUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        Container(color: Colors.grey[800]),
                              )
                              : Container(color: Colors.grey[800]),
                    ),
                  ),

                  // Movie details
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster and basic info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Poster
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child:
                                    _posterUrl != null
                                        ? Image.network(
                                          _posterUrl!,
                                          width: 120,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                                width: 120,
                                                height: 180,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.movie,
                                                  size: 50,
                                                ),
                                              ),
                                        )
                                        : Container(
                                          width: 120,
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.movie,
                                            size: 50,
                                          ),
                                        ),
                              ),
                              const SizedBox(width: 16),

                              // Movie info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.movie.year != null &&
                                        widget.movie.year!.isNotEmpty)
                                      Text(
                                        'Year: ${widget.movie.year}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    if (widget.movie.duration != null &&
                                        widget.movie.duration!.isNotEmpty)
                                      Text(
                                        'Duration: ${widget.movie.duration}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    if (widget.movie.rating != null &&
                                        widget.movie.rating!.isNotEmpty)
                                      Text(
                                        'Rating: ${widget.movie.rating}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _playMovie,
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Play'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Description
                          if (widget.movie.description != null &&
                              widget.movie.description!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.movie.description!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
