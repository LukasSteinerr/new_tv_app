import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/playlist.dart';
import '../models/tv_series.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import '../widgets/content_carousel.dart';
import '../widgets/tv_series_card.dart';
import '../widgets/featured_content.dart';
import 'netflix_style_tv_series_detail_screen.dart';
import 'category_content_screen.dart';

class TvSeriesScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const TvSeriesScreen({
    super.key,
    required this.playlistService,
    required this.playlist,
  });

  @override
  State<TvSeriesScreen> createState() => _TvSeriesScreenState();
}

class _TvSeriesScreenState extends State<TvSeriesScreen> {
  List<Category> _categories = [];
  Map<int, List<TvSeries>> _categorySeries = {};
  bool _isLoading = true;
  TvSeries? _featuredSeries;
  late ScrollController _scrollController;
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      double offset = _scrollController.offset;
      double quickThreshold = 10.0;
      double targetOpacity = 0.7;
      double newOpacity;

      if (offset <= 0) {
        newOpacity = 0.0;
      } else {
        newOpacity = (offset / quickThreshold).clamp(0.0, targetOpacity);
      }

      if (newOpacity != _appBarOpacity) {
        if (mounted) {
          setState(() {
            _appBarOpacity = newOpacity;
          });
        }
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

      // Select a featured series (one with a TMDB ID if possible)
      TvSeries? featuredSeries;
      if (allSeries.isNotEmpty) {
        // First try to find a series with a TMDB ID
        featuredSeries = allSeries.firstWhere(
          (s) => s.tmdbId != null && s.tmdbId!.isNotEmpty,
          orElse: () => allSeries.first,
        );
      }

      if (mounted) {
        setState(() {
          _categories = seriesCategories;
          _categorySeries = categorySeriesMap;
          _featuredSeries = featuredSeries;
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

    if (_categories.isEmpty && _featuredSeries == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
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

    if (_featuredSeries != null) {
      featuredImageUrls.add(_featuredSeries!.coverUrl ?? '');
      featuredPlayActions.add(() => _navigateToSeries(_featuredSeries!));
      featuredDetailsActions.add(() => _navigateToSeries(_featuredSeries!));

      final allOtherSeries =
          _categorySeries.values
              .expand((seriesList) => seriesList)
              .where(
                (s) =>
                    s.id != _featuredSeries!.id &&
                    (s.coverUrl != null && s.coverUrl!.isNotEmpty),
              )
              .take(5)
              .toList();

      for (var seriesItem in allOtherSeries) {
        featuredImageUrls.add(seriesItem.coverUrl ?? '');
        featuredPlayActions.add(() => _navigateToSeries(seriesItem));
        featuredDetailsActions.add(() => _navigateToSeries(seriesItem));
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(_appBarOpacity),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.playlist.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 30),
            onPressed: () {
              // TODO: Implement Search
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Search tapped!')));
            },
            tooltip: 'Search',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          if (featuredImageUrls.isNotEmpty)
            SliverToBoxAdapter(
              child: FeaturedContent(
                key: ValueKey(_featuredSeries?.id ?? 'featured_series'),
                imageUrls: featuredImageUrls,
                onPlayTapped: (index) {
                  if (index < featuredPlayActions.length)
                    featuredPlayActions[index]();
                },
                onDetailsTapped: (index) {
                  if (index < featuredDetailsActions.length)
                    featuredDetailsActions[index]();
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
