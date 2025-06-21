import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:flutter_rating/flutter_rating.dart';
import '../models/tv_series.dart';
import '../models/tv_episode.dart';
import '../services/download_service.dart';
import '../services/objectbox_service.dart';
import '../services/playlist_service.dart';
import '../services/tmdb_image_provider.dart';
import 'universal_video_player.dart';

class NetflixStyleTvSeriesDetailScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final TvSeries series;

  const NetflixStyleTvSeriesDetailScreen({
    super.key,
    required this.playlistService,
    required this.series,
  });

  @override
  State<NetflixStyleTvSeriesDetailScreen> createState() =>
      _NetflixStyleTvSeriesDetailScreenState();
}

class _NetflixStyleTvSeriesDetailScreenState
    extends State<NetflixStyleTvSeriesDetailScreen> {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
  ObjectBoxService? _objectBoxService;
  List<TvEpisode> _episodes = [];
  Map<int, List<TvEpisode>> _seasonEpisodes = {};
  List<int> _seasons = [];
  bool _isLoading = true;
  int? _selectedSeason;
  String? _posterUrl;
  String? _backdropUrl;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setPortraitMode(); // Ensure portrait mode on init
  }

  Future<void> _initializeServices() async {
    _objectBoxService = await ObjectBoxService.create();
    _loadEpisodes();
    _loadTMDBData();
  }

  void _setPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _loadTMDBData() async {
    if (widget.series.tmdbId != null && widget.series.tmdbId!.isNotEmpty) {
      try {
        // Load poster and backdrop in parallel
        final posterFuture = _imageProvider.getTvPosterUrl(
          widget.series.tmdbId,
          widget.series.coverUrl,
        );
        final backdropFuture = _imageProvider.getTvBackdropUrl(
          widget.series.tmdbId,
        );

        final results = await Future.wait([posterFuture, backdropFuture]);

        if (mounted) {
          setState(() {
            _posterUrl = results[0]; // Poster URL
            _backdropUrl = results[1]; // Backdrop URL
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _posterUrl = widget.series.coverUrl;
          });
        }
      }
    } else {
      setState(() {
        _posterUrl = widget.series.coverUrl;
      });
    }
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final episodes = await widget.playlistService.getTvSeriesEpisodes(
        widget.series,
      );

      // Group episodes by season
      final seasonEpisodes = <int, List<TvEpisode>>{};
      for (final episode in episodes) {
        if (!seasonEpisodes.containsKey(episode.seasonNumber)) {
          seasonEpisodes[episode.seasonNumber] = [];
        }
        seasonEpisodes[episode.seasonNumber]!.add(episode);
      }

      // Sort episodes within each season
      for (final season in seasonEpisodes.keys) {
        seasonEpisodes[season]!.sort(
          (a, b) => a.episodeNumber.compareTo(b.episodeNumber),
        );
      }

      // Get sorted list of seasons
      final seasons = seasonEpisodes.keys.toList()..sort();

      if (mounted) {
        setState(() {
          _episodes = episodes;
          _seasonEpisodes = seasonEpisodes;
          _seasons = seasons;
          _selectedSeason = seasons.isNotEmpty ? seasons.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Show a more user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load episodes. Please try again later.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(label: 'Retry', onPressed: _loadEpisodes),
          ),
        );

        // Set empty state but not loading
        setState(() {
          _episodes = [];
          _seasonEpisodes = {};
          _seasons = [];
          _selectedSeason = null;
          _isLoading = false;
        });
      }
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
      body: SingleChildScrollView(
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
                  // Title row with Netflix-style logo
                  _buildTitleRow(),

                  // Metadata row (year, language, HD)
                  _buildMetadataRow(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Overview/Synopsis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildOverview(),
            ),

            const SizedBox(height: 16),

            // Season selector
            _buildSeasonSelector(),

            const SizedBox(height: 16),

            // Episodes list
            _buildEpisodesList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Play the first episode of the selected season
  void _toggleMyList() {
    if (_objectBoxService == null) return;
    setState(() {
      if (widget.series.myList == 1) {
        widget.series.myList = 0;
      } else {
        widget.series.myList = 1;
      }
      _objectBoxService!.addTvSeries(widget.series);
    });
  }

  void _playFirstEpisode() async {
    // Made async
    if (_selectedSeason != null &&
        _seasonEpisodes.containsKey(_selectedSeason)) {
      final episodes = _seasonEpisodes[_selectedSeason]!;
      if (episodes.isNotEmpty) {
        await Navigator.push(
          // await
          context,
          MaterialPageRoute(
            builder: (context) => UniversalVideoPlayer(episode: episodes.first),
          ),
        );
        _setPortraitMode(); // Restore portrait mode
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        ); // Restore UI
      }
    }
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
            onTap: _playFirstEpisode,
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
            ],
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
            widget.series.name,
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
            child: const Icon(Icons.tv, color: Colors.red, size: 30),
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
          if (widget.series.year != null && widget.series.year!.isNotEmpty)
            Text(
              widget.series.year!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          if (widget.series.year != null && widget.series.year!.isNotEmpty)
            const SizedBox(width: 12),
          if (widget.series.rating != null && widget.series.rating!.isNotEmpty)
            StarRating(
              rating: (double.tryParse(widget.series.rating!) ?? 0.0) / 2,
              starCount: 5,
              size: 20.0,
              color: Colors.orange,
              borderColor: Colors.grey,
              allowHalfRating: true,
            ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleMyList,
            child: Icon(
              widget.series.myList == 1 ? Icons.check : Icons.add,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
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

  Widget _buildOverview() {
    if (widget.series.description == null ||
        widget.series.description!.isEmpty) {
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
          widget.series.description!,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSeasonSelector() {
    if (_seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Episodes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedSeason,
                  hint: const Text(
                    'Select Season',
                    style: TextStyle(color: Colors.white),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _selectedSeason = value;
                    });
                  },
                  items:
                      _seasons.map((season) {
                        return DropdownMenuItem<int>(
                          value: season,
                          child: Text('Season $season'),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    if (_episodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No episodes found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_selectedSeason == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('Select a season', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final seasonEpisodes = _seasonEpisodes[_selectedSeason] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: seasonEpisodes.length,
        itemBuilder: (context, index) {
          final episode = seasonEpisodes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UniversalVideoPlayer(episode: episode),
                  ),
                );
                _setPortraitMode();
                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.manual,
                  overlays: SystemUiOverlay.values,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 84,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child:
                                  episode.coverUrl != null &&
                                          episode.coverUrl!.isNotEmpty
                                      ? Image.network(
                                        episode.coverUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.movie,
                                                color: Colors.white,
                                              ),
                                            ),
                                      )
                                      : Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.movie,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                          Icon(
                            Icons.play_circle_outline,
                            color: Colors.white.withOpacity(0.8),
                            size: 40,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${episode.episodeNumber}. ${episode.title}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (episode.duration != null &&
                                episode.duration!.isNotEmpty)
                              Text(
                                episode.duration!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.download_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          DownloadService().startDownload(episode);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Starting download...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (episode.description != null &&
                      episode.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        episode.description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
