import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_image_provider.dart';
import 'movie_player_screen.dart';

class NetflixStyleMovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const NetflixStyleMovieDetailScreen({Key? key, required this.movie})
    : super(key: key);

  @override
  State<NetflixStyleMovieDetailScreen> createState() =>
      _NetflixStyleMovieDetailScreenState();
}

class _NetflixStyleMovieDetailScreenState
    extends State<NetflixStyleMovieDetailScreen> {
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
    final Size size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with backdrop image
            _buildHeader(size),

            // Title and metadata section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with Netflix-style logo
                  _buildTitleRow(),

                  // Metadata row (year, language, HD)
                  _buildMetadataRow(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Play button
            _buildPlayButton(),

            const SizedBox(height: 16),

            // Overview/Synopsis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildOverview(),
            ),

            const SizedBox(height: 16),

            // Action buttons row
            _buildActionButtonsRow(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Stack(
      children: [
        // Backdrop image
        SizedBox(
          height: size.height * 0.4,
          width: double.infinity,
          child:
              _backdropUrl != null
                  ? Image.network(
                    _backdropUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(color: Colors.black),
                  )
                  : Container(color: Colors.black),
        ),

        // Gradient overlay for better text visibility
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 40,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Text(
            widget.movie.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // Netflix-style logo
        Expanded(
          flex: 1,
          child: Container(
            alignment: Alignment.centerRight,
            child: const Icon(Icons.movie, color: Colors.red, size: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          if (widget.movie.year != null && widget.movie.year!.isNotEmpty)
            Text(
              widget.movie.year!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          if (widget.movie.year != null && widget.movie.year!.isNotEmpty)
            const SizedBox(width: 12),
          if (widget.movie.rating != null && widget.movie.rating!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                widget.movie.rating!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          if (widget.movie.duration != null &&
              widget.movie.duration!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                widget.movie.duration!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          const Spacer(),
          // HD tag if available
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'HD',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _playMovie,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    if (widget.movie.description == null || widget.movie.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.movie.description!,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildActionButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.add, 'My List'),
          _buildActionButton(Icons.thumb_up_outlined, 'Rate'),
          _buildActionButton(Icons.share, 'Share'),
          _buildActionButton(Icons.download, 'Download'),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
