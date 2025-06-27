import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/tv_series.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import '../widgets/content_carousel.dart';
import '../widgets/tv_series_card.dart';
import '../widgets/featured_content.dart';
import 'netflix_style_tv_series_detail_screen.dart';
import 'category_content_screen.dart';
import 'universal_video_player.dart';

class TvSeriesScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;
  final Function(double scrollOffset)? onScrollUpdate; // Add callback

  const TvSeriesScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
    this.onScrollUpdate, // Add callback parameter
  });

  @override
  State<TvSeriesScreen> createState() => _TvSeriesScreenState();
}

class _TvSeriesScreenState extends State<TvSeriesScreen> {
  List<Category> _categories = [];
  Map<int, List<TvSeries>> _categorySeries = {};
  List<TvSeries> _featuredTvSeries = []; // Added for popular TMDB TV series
  bool _isLoading = true;
  TvSeries? _featuredSeriesToShow; // Renamed for clarity
  late ScrollController _scrollController;
  // _appBarOpacity is now managed by the parent, remove from here
  // double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(
      _notifyScrollUpdate,
    ); // Use a dedicated method
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_notifyScrollUpdate); // Remove listener
    _scrollController.dispose();
    super.dispose();
  }

  void _notifyScrollUpdate() {
    if (widget.onScrollUpdate != null) {
      widget.onScrollUpdate!(_scrollController.offset); // Call the callback
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get only series categories
      final allCategories = await widget.playlistService.getPlaylistCategories(
        widget.playlist.id,
      );
      final seriesCategories =
          allCategories.where((category) => category.isSeries).toList();

      // Get series for each category
      final categorySeriesMap = <int, List<TvSeries>>{};
      List<TvSeries> allSeries = [];

      for (final category in seriesCategories) {
        final series = await widget.playlistService.getCategoryTvSeries(
          category.id,
        );
        categorySeriesMap[category.id] = series;
        allSeries.addAll(series);
      }

      // Get featured TV series from the database
      final featuredTvSeries = await widget.playlistService.getFeaturedTvSeries(
        widget.playlist.id,
      );

      // Determine the primary featured series (e.g., the first from the featured list)
      TvSeries? featuredSeriesToShow;
      if (featuredTvSeries.isNotEmpty) {
        featuredSeriesToShow = featuredTvSeries.first;
      } else {
        // Fallback to any local series if no featured series are found
        if (allSeries.isNotEmpty) {
          featuredSeriesToShow = allSeries.firstWhere(
            (s) => s.tmdbId != null && s.tmdbId!.isNotEmpty,
            orElse: () => allSeries.first,
          );
        }
      }

      if (mounted) {
        setState(() {
          _categories = seriesCategories;
          _categorySeries = categorySeriesMap;
          _featuredTvSeries = featuredTvSeries; // Store fetched featured series
          _featuredSeriesToShow = featuredSeriesToShow;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading TV series: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSeries(TvSeries series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NetflixStyleTvSeriesDetailScreen(
              playlistService: widget.playlistService,
              series: series,
            ),
      ),
    );
  }

  void _playFirstEpisode(TvSeries series) async {
    try {
      final episodes = await widget.playlistService.getTvSeriesEpisodes(series);
      if (episodes.isNotEmpty && episodes.first.streamUrl.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UniversalVideoPlayer(episode: episodes.first),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No playable episodes found for this series.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading episodes: $e')));
    }
  }

  void _navigateToSeeAll(Category category, List<TvSeries> seriesList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CategoryContentScreen(
              category: category,
              items: seriesList,
              playlistService: widget.playlistService,
            ),
      ),
    );
  }

  // Copied and adapted from UI/lib/home_screen.dart / movies_screen.dart
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onSeeAllTapped,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 24.0,
          left: 16.0,
          right: 16.0,
          bottom: 12.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onSeeAllTapped,
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_categories.isEmpty && _featuredSeriesToShow == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          // Keep this basic AppBar for the empty state
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.playlist.name,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text(
            'No TV series found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    List<String> featuredImageUrls = [];
    List<Function()> featuredPlayActions = [];
    List<Function()> featuredDetailsActions = [];

    // Use popular TMDB TV series for featured content
    if (_featuredTvSeries.isNotEmpty) {
      // Take up to 4 popular TV series for the featured section
      final seriesToShowInFeatured = _featuredTvSeries.take(4).toList();

      for (var series in seriesToShowInFeatured) {
        // Prefer featuredPosterUrl for featured content, then coverUrl.
        String imageUrl = series.featuredPosterUrl ?? series.coverUrl ?? '';
        featuredImageUrls.add(imageUrl);
        featuredPlayActions.add(() => _playFirstEpisode(series));
        featuredDetailsActions.add(() => _navigateToSeries(series));
      }
    }
    // Fallback if TMDB series are not available but a _featuredSeriesToShow (from playlist) exists
    else if (_featuredSeriesToShow != null) {
      featuredImageUrls.add(_featuredSeriesToShow!.coverUrl ?? '');
      featuredPlayActions.add(() => _playFirstEpisode(_featuredSeriesToShow!));
      featuredDetailsActions.add(
        () => _navigateToSeries(_featuredSeriesToShow!),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      // AppBar is removed from here and will be in the parent XtreamPlaylistScreen
      body: CustomScrollView(
        controller:
            _scrollController, // Keep controller for opacity calculation
        slivers: <Widget>[
          // Remove top padding, content should go behind the parent AppBar
          if (featuredImageUrls.isNotEmpty)
            SliverToBoxAdapter(
              child: FeaturedContent(
                key: ValueKey(
                  _featuredTvSeries.isNotEmpty
                      ? _featuredTvSeries.map((s) => s.tmdbId ?? s.id).join(',')
                      : _featuredSeriesToShow?.id ?? 'featured_series',
                ), // More robust key
                imageUrls: featuredImageUrls,
                onPlayTapped: (index) {
                  if (index < featuredPlayActions.length) {
                    featuredPlayActions[index]();
                  }
                },
                onDetailsTapped: (index) {
                  if (index < featuredDetailsActions.length) {
                    featuredDetailsActions[index]();
                  }
                },
              ),
            ),

          ..._categories.expand((category) {
            final seriesList = _categorySeries[category.id] ?? [];
            if (seriesList.isEmpty) {
              return [const SliverToBoxAdapter(child: SizedBox.shrink())];
            }

            return [
              _buildSectionHeader(
                context,
                category.name,
                () => _navigateToSeeAll(category, seriesList),
              ),
              SliverToBoxAdapter(
                child: ContentCarousel<TvSeries>(
                  items: seriesList,
                  itemBuilder:
                      (series) => TvSeriesCard(
                        // This will need to be updated like MovieCard
                        series: series,
                        onTap: () => _navigateToSeries(series),
                      ),
                ),
              ),
            ];
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
