import 'package:flutter/material.dart';
import '../models/tv_series.dart';
import '../models/tv_episode.dart';
import '../services/playlist_service.dart';
import '../services/tmdb_image_provider.dart';
import 'tv_episode_player_screen.dart';

class TvSeriesDetailScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final TvSeries series;

  const TvSeriesDetailScreen({
    super.key,
    required this.playlistService,
    required this.series,
  });

  @override
  State<TvSeriesDetailScreen> createState() => _TvSeriesDetailScreenState();
}

class _TvSeriesDetailScreenState extends State<TvSeriesDetailScreen> {
  final TMDBImageProvider _imageProvider = TMDBImageProvider();
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
    _loadEpisodes();
    _loadTMDBData();
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
                      title: Text(widget.series.name),
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

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cover image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child:
                                _posterUrl != null && _posterUrl!.isNotEmpty
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
                                              Icons.tv,
                                              size: 50,
                                            ),
                                          ),
                                    )
                                    : Container(
                                      width: 120,
                                      height: 180,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.tv, size: 50),
                                    ),
                          ),
                          const SizedBox(width: 16),
                          // Series details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.series.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (widget.series.year != null &&
                                        widget.series.year!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16.0,
                                        ),
                                        child: Text(
                                          'Year: ${widget.series.year}',
                                        ),
                                      ),
                                    if (widget.series.rating != null &&
                                        widget.series.rating!.isNotEmpty)
                                      Text('Rating: ${widget.series.rating}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (widget.series.description != null &&
                                    widget.series.description!.isNotEmpty)
                                  Text(
                                    widget.series.description!,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Season selector
                  SliverToBoxAdapter(
                    child:
                        _seasons.isNotEmpty
                            ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: DropdownButton<int>(
                                value: _selectedSeason,
                                hint: const Text('Select Season'),
                                isExpanded: true,
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
                            )
                            : const SizedBox.shrink(),
                  ),

                  // Episodes list
                  SliverFillRemaining(
                    child:
                        _episodes.isEmpty
                            ? const Center(child: Text('No episodes found'))
                            : _selectedSeason == null
                            ? const Center(child: Text('Select a season'))
                            : ListView.builder(
                              itemCount:
                                  _seasonEpisodes[_selectedSeason]?.length ?? 0,
                              itemBuilder: (context, index) {
                                final episode =
                                    _seasonEpisodes[_selectedSeason]![index];
                                return ListTile(
                                  leading:
                                      episode.coverUrl != null &&
                                              episode.coverUrl!.isNotEmpty
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                            child: Image.network(
                                              episode.coverUrl!,
                                              width: 60,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) => Container(
                                                    width: 60,
                                                    height: 40,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.movie,
                                                      size: 20,
                                                    ),
                                                  ),
                                            ),
                                          )
                                          : Container(
                                            width: 60,
                                            height: 40,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.movie,
                                              size: 20,
                                            ),
                                          ),
                                  title: Text(episode.title),
                                  subtitle: Text(
                                    'S${episode.seasonNumber}:E${episode.episodeNumber}',
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => TvEpisodePlayerScreen(
                                              episode: episode,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
