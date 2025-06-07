import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import '../models/movie.dart';
import '../services/objectbox_service.dart';
import '../services/tmdb_image_provider.dart';
import '../services/tmdb_service.dart'; // Import TMDBService
import 'universal_video_player.dart';
import '../services/download_service.dart';

class NetflixStyleMovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const NetflixStyleMovieDetailScreen({super.key, required this.movie});

  @override
  State<NetflixStyleMovieDetailScreen> createState() =>
      _NetflixStyleMovieDetailScreenState();
}

class _NetflixStyleMovieDetailScreenState
    extends State<NetflixStyleMovieDetailScreen> {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  final TMDBService _tmdbService = TMDBService(); // Instantiate TMDBService
  ObjectBoxService? _objectBoxService;
  bool _isLoading = true;
  String? _posterUrl;
  String? _backdropUrl;
  String? _overview; // Add a field for overview

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setPortraitMode(); // Ensure portrait mode on init
  }

  Future<void> _initializeServices() async {
    _objectBoxService = await ObjectBoxService.create();
    _loadTMDBData();
  }

  void _setPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _loadTMDBData() async {
    if (widget.movie.tmdbId != null && widget.movie.tmdbId!.isNotEmpty) {
      try {
        // Load poster, backdrop, and movie details in parallel
        final posterFuture = _imageProvider.getPosterUrl(
          widget.movie.tmdbId,
          widget.movie.coverUrl,
        );
        final backdropFuture = _imageProvider.getBackdropUrl(
          widget.movie.tmdbId,
        );
        final movieDetailsFuture = _tmdbService.getMovieDetails(
          widget.movie.tmdbId!,
        ); // Fetch movie details

        final results = await Future.wait([
          posterFuture,
          backdropFuture,
          movieDetailsFuture,
        ]);

        if (mounted) {
          setState(() {
            _posterUrl = results[0] as String?; // Poster URL
            _backdropUrl = results[1] as String?; // Backdrop URL
            final movieDetails =
                results[2] as Map<String, dynamic>?; // Movie details
            _overview =
                movieDetails?['overview'] as String?; // Extract overview
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading TMDB data: $e'); // Print error for debugging
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

  void _playMovie() async {
    // Made async to await Navigator.pop
    // UniversalVideoPlayer will set landscape mode
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversalVideoPlayer(movie: widget.movie),
      ),
    );
    // After returning from player, ensure detail screen is portrait
    _setPortraitMode();
    // Also restore SystemUIOverlays if needed, though UniversalVideoPlayer should handle its own.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _toggleMyList() {
    if (_objectBoxService == null) return;
    setState(() {
      if (widget.movie.myList == 1) {
        widget.movie.myList = 0;
      } else {
        widget.movie.myList = 1;
      }
      _objectBoxService!.addMovie(widget.movie);
    });
  }

  void _downloadMovie() {
    DownloadService().startDownload(widget.movie);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting download...'),
        backgroundColor: Colors.green,
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
                  // Title
                  Text(
                    widget.movie.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        // Mimicking the orange glow from the image
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.orangeAccent.withOpacity(0.7),
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Metadata row (match percentage, year, duration, rating, HD)
                  Row(
                    children: [
                      // Assuming you have a match percentage in your Movie model
                      // Text(
                      //   '${movie.matchPercentage} Match',
                      //   style: TextStyle(
                      //     color: Colors.greenAccent,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      // SizedBox(width: 8),
                      if (widget.movie.year != null &&
                          widget.movie.year!.isNotEmpty)
                        Text(
                          widget.movie.year!,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      if (widget.movie.year != null &&
                          widget.movie.year!.isNotEmpty)
                        SizedBox(width: 8),
                      if (widget.movie.duration != null &&
                          widget.movie.duration!.isNotEmpty)
                        Text(
                          widget.movie.duration!,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      if (widget.movie.duration != null &&
                          widget.movie.duration!.isNotEmpty)
                        SizedBox(width: 8),
                      if (widget.movie.rating != null &&
                          widget.movie.rating!.isNotEmpty)
                        Text(
                          widget.movie.rating!,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      if (widget.movie.rating != null &&
                          widget.movie.rating!.isNotEmpty)
                        SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[600]!),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'HD',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: _toggleMyList,
                        child: Icon(
                          widget.movie.myList == 1 ? Icons.check : Icons.add,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: _downloadMovie,
                        child: const Icon(
                          Icons.cloud_download_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Most Liked row
                  Row(
                    children: [
                      Icon(Icons.thumb_up_alt, color: Colors.orange, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Most Liked',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Play button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                icon: Icon(Icons.play_arrow),
                label: Text('Play'),
                onPressed: _playMovie,
              ),
            ),

            const SizedBox(height: 24),

            // Overview/Synopsis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_overview != null &&
                      _overview!.isNotEmpty) // Use _overview
                    Text(
                      _overview!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Top Cast section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Cast',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Assuming you have a list of actors in your Movie model
                  // Container(
                  //   height: 150, // Adjust height as needed
                  //   child: ListView.builder(
                  //     scrollDirection: Axis.horizontal,
                  //     itemCount: movie.cast.length,
                  //     itemBuilder: (context, index) {
                  //       final actor = movie.cast[index];
                  //       return Padding(
                  //         padding: const EdgeInsets.only(right: 16.0),
                  //         child: Column(
                  //           children: [
                  //             CircleAvatar(
                  //               radius: 40,
                  //               backgroundImage: NetworkImage(actor.imageUrl),
                  //               onBackgroundImageError:
                  //                   (exception, stackTrace) =>
                  //                       Icon(Icons.person, size: 40),
                  //               backgroundColor: Colors.grey[800],
                  //             ),
                  //             SizedBox(height: 8),
                  //             Text(
                  //               actor.name,
                  //               style: TextStyle(
                  //                 color: Colors.white,
                  //                 fontSize: 12,
                  //               ),
                  //             ),
                  //             Text(
                  //               actor.characterName,
                  //               style: TextStyle(
                  //                 color: Colors.grey[500],
                  //                 fontSize: 10,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                ],
              ),
            ),

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
                  Colors.black.withAlpha(179), // 0.7 opacity
                  Colors.black,
                ],
              ),
            ),
          ),
        ),

        // Play button in the center of the backdrop - exactly like Netflix clone
        Positioned(
          top: 100,
          bottom: 100,
          right: 100,
          left: 100,
          child: GestureDetector(
            onTap: _playMovie,
            child: const Icon(
              Icons.play_circle_outline,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),

        // Cross and Cast buttons - exactly like Netflix clone
        Positioned(
          right: 15,
          top: 50,
          child: Row(
            children: [
              GestureDetector(
                onTap: Navigator.of(context).pop,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // Cast functionality would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cast button pressed')),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: const Icon(Icons.cast, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
