import 'package:flutter/material.dart';
import '../models/tv_series.dart';
import '../models/tv_episode.dart';
import '../services/playlist_service.dart';
import 'tv_episode_player_screen.dart';

class TvSeriesDetailScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final TvSeries series;

  const TvSeriesDetailScreen({
    Key? key,
    required this.playlistService,
    required this.series,
  }) : super(key: key);

  @override
  State<TvSeriesDetailScreen> createState() => _TvSeriesDetailScreenState();
}

class _TvSeriesDetailScreenState extends State<TvSeriesDetailScreen> {
  List<TvEpisode> _episodes = [];
  Map<int, List<TvEpisode>> _seasonEpisodes = {};
  List<int> _seasons = [];
  bool _isLoading = true;
  int? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final episodes = await widget.playlistService.getTvSeriesEpisodes(widget.series);
      
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
        seasonEpisodes[season]!.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      }
      
      // Get sorted list of seasons
      final seasons = seasonEpisodes.keys.toList()..sort();
      
      setState(() {
        _episodes = episodes;
        _seasonEpisodes = seasonEpisodes;
        _seasons = seasons;
        _selectedSeason = seasons.isNotEmpty ? seasons.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading episodes: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.series.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Series info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: widget.series.coverUrl != null && widget.series.coverUrl!.isNotEmpty
                            ? Image.network(
                                widget.series.coverUrl!,
                                width: 120,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.tv, size: 50),
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
                                if (widget.series.year != null && widget.series.year!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Text('Year: ${widget.series.year}'),
                                  ),
                                if (widget.series.rating != null && widget.series.rating!.isNotEmpty)
                                  Text('Rating: ${widget.series.rating}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (widget.series.description != null && widget.series.description!.isNotEmpty)
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
                
                // Season selector
                if (_seasons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButton<int>(
                      value: _selectedSeason,
                      hint: const Text('Select Season'),
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          _selectedSeason = value;
                        });
                      },
                      items: _seasons.map((season) {
                        return DropdownMenuItem<int>(
                          value: season,
                          child: Text('Season $season'),
                        );
                      }).toList(),
                    ),
                  ),
                
                // Episodes list
                Expanded(
                  child: _episodes.isEmpty
                      ? const Center(child: Text('No episodes found'))
                      : _selectedSeason == null
                          ? const Center(child: Text('Select a season'))
                          : ListView.builder(
                              itemCount: _seasonEpisodes[_selectedSeason]?.length ?? 0,
                              itemBuilder: (context, index) {
                                final episode = _seasonEpisodes[_selectedSeason]![index];
                                return ListTile(
                                  leading: episode.coverUrl != null && episode.coverUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4.0),
                                          child: Image.network(
                                            episode.coverUrl!,
                                            width: 60,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 60,
                                              height: 40,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.movie, size: 20),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 40,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.movie, size: 20),
                                        ),
                                  title: Text(episode.title),
                                  subtitle: Text('S${episode.seasonNumber}:E${episode.episodeNumber}'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TvEpisodePlayerScreen(episode: episode),
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
