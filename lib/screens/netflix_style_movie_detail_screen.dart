import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:readmore/readmore.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:flutter_rating/flutter_rating.dart';
import 'package:go_router/go_router.dart';
import '../models/cast.dart';
import '../models/movie.dart';
import '../services/objectbox_service.dart';
import '../services/tmdb_image_provider.dart';
import '../services/tmdb_service.dart'; // Import TMDBService
import 'universal_video_player.dart';
import '../services/download_service.dart';
import 'all_actors_screen.dart'; // Import the new screen
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  List<String> _genres = [];
  List<Movie> _similarMovies = [];

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
        final creditsFuture = _tmdbService.getMovieCredits(
          widget.movie.tmdbId!,
        );
        final similarMoviesFuture = _tmdbService.getSimilarMovies(
          widget.movie.tmdbId!,
        );

        final results = await Future.wait([
          posterFuture,
          backdropFuture,
          movieDetailsFuture,
          creditsFuture,
          similarMoviesFuture,
        ]);

        if (mounted) {
          setState(() {
            _posterUrl = results[0] as String?; // Poster URL
            _backdropUrl = results[1] as String?; // Backdrop URL
            final movieDetails =
                results[2] as Map<String, dynamic>?; // Movie details
            if (movieDetails != null && movieDetails['genres'] != null) {
              _genres =
                  (movieDetails['genres'] as List)
                      .map((genre) => genre['name'] as String)
                      .toList();
            }
            _overview =
                movieDetails?['overview'] as String?; // Extract overview
            widget.movie.cast = results[3] as List<Cast>;
            _similarMovies = results[4] as List<Movie>;
            _isLoading = false;
          });
          _crossReferenceSimilarMovies();
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
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all["Pro"] != null &&
          customerInfo.entitlements.all["Pro"]!.isActive) {
        // User is subscribed, play the movie
        _startPlayback();
      } else {
        // User is not subscribed, show the paywall
        final paywallResult = await RevenueCatUI.presentPaywallIfNeeded("Pro");
        log("Paywall result: $paywallResult");
        if (paywallResult == PaywallResult.purchased) {
          _startPlayback();
        }
      }
    } on PlatformException catch (e) {
      log("Paywall error: ${e.message}");
    }
  }

  void _startPlayback() async {
    final appDir = await getApplicationDocumentsDirectory();
    final localPath = '${appDir.path}/movies/${widget.movie.name}.mp4';
    final localFile = File(localPath);

    if (localFile.existsSync()) {
      // Play from local file
      await context.push(
        '/video-player',
        extra: {'movie': widget.movie, 'localPath': localPath},
      );
    } else {
      // Play from stream URL
      await context.push('/video-player', extra: {'movie': widget.movie});
    }

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

  void _downloadMovie() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all["Pro"] != null &&
          customerInfo.entitlements.all["Pro"]!.isActive) {
        // User is subscribed, start the download
        DownloadService().startDownload(widget.movie);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starting download...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // User is not subscribed, show the paywall
        final paywallResult = await RevenueCatUI.presentPaywallIfNeeded("Pro");
        log("Paywall result: $paywallResult");
        if (paywallResult == PaywallResult.purchased) {
          DownloadService().startDownload(widget.movie);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Starting download...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      log("Paywall error: ${e.message}");
    }
  }

  Future<void> _crossReferenceSimilarMovies() async {
    if (_objectBoxService == null || _similarMovies.isEmpty) return;

    final List<Movie> syncedSimilarMovies = [];
    for (final tmdbMovie in _similarMovies) {
      if (tmdbMovie.tmdbId != null) {
        final localMovie = _objectBoxService!.getMovieByTmdbId(
          tmdbMovie.tmdbId!,
        );
        if (localMovie != null) {
          localMovie.posterUrl = tmdbMovie.posterUrl;
          localMovie.backdropUrl = tmdbMovie.backdropUrl;
          localMovie.featuredPosterUrl = tmdbMovie.featuredPosterUrl;
          syncedSimilarMovies.add(localMovie);
        }
      }
    }

    if (mounted) {
      setState(() {
        _similarMovies = syncedSimilarMovies;
      });
    }
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
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
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
                      // Genres
                      if (_genres.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children:
                                _genres
                                    .map(
                                      (genre) => Chip(
                                        label: Text(genre),
                                        backgroundColor: Colors.grey[800],
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
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
                          // Star Rating
                          if (widget.movie.rating != null &&
                              widget.movie.rating!.isNotEmpty)
                            Row(
                              children: [
                                StarRating(
                                  rating:
                                      (double.tryParse(widget.movie.rating!) ??
                                          0.0) /
                                      2,
                                  starCount: 5,
                                  size: 20.0,
                                  color: Colors.orange,
                                  borderColor: Colors.grey,
                                  allowHalfRating: true,
                                ),
                              ],
                            ),
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
                              widget.movie.myList == 1
                                  ? Icons.check
                                  : Icons.add,
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
                        borderRadius: BorderRadius.circular(25),
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
                        ReadMoreText(
                          _overview!,
                          trimLines: 3,
                          colorClickableText: Colors.pink,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: 'Show more',
                          trimExpandedText: 'Show less',
                          moreStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              (widget.movie.cast?.length ?? 0) > 10
                                  ? 11
                                  : (widget.movie.cast?.length ?? 0),
                          itemBuilder: (context, index) {
                            if (index == 10) {
                              return GestureDetector(
                                onTap: () {
                                  context.push(
                                    '/all-actors',
                                    extra: widget.movie,
                                  );
                                },
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Colors.grey[800],
                                        child: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'See All',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final actor = widget.movie.cast![index];
                            final profileUrl =
                                actor.profilePath != null
                                    ? TMDBService.getPosterUrl(
                                      actor.profilePath!,
                                    )
                                    : null;

                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: SizedBox(
                                width: 80,
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          profileUrl != null
                                              ? CachedNetworkImageProvider(
                                                profileUrl,
                                              )
                                              : null,
                                      backgroundColor: Colors.grey[800],
                                      child:
                                          profileUrl == null
                                              ? const Icon(
                                                Icons.person,
                                                size: 40,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      actor.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      actor.character,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildSimilarMovies(),
              ],
            ),
          ),
          Positioned(
            top: 50,
            right: 15,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarMovies() {
    if (_similarMovies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Similar Movies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200, // Adjust height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _similarMovies.length,
            itemBuilder: (context, index) {
              final movie = _similarMovies[index];
              return GestureDetector(
                onTap: () {
                  context.push('/movie-detail', extra: movie);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: SizedBox(
                    width: 120, // Adjust width as needed
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child:
                              movie.posterUrl != null
                                  ? CachedNetworkImage(
                                    imageUrl: movie.posterUrl!,
                                    height: 160,
                                    width: 110,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => Container(
                                          height: 160,
                                          width: 110,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.movie,
                                            color: Colors.white,
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          height: 160,
                                          width: 110,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.movie,
                                            color: Colors.white,
                                          ),
                                        ),
                                  )
                                  : Container(
                                    height: 160,
                                    width: 110,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.movie,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movie.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
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
                  ? CachedNetworkImage(
                    imageUrl: _backdropUrl!,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(color: Colors.black),
                    errorWidget:
                        (context, url, error) => Container(color: Colors.black),
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
      ],
    );
  }
}
