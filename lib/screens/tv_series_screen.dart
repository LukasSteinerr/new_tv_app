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

class TvSeriesScreen extends StatefulWidget {
  final PlaylistService playlistService;
  final Playlist playlist;

  const TvSeriesScreen({
    Key? key,
    required this.playlistService,
    required this.playlist,
  }) : super(key: key);

  @override
  State<TvSeriesScreen> createState() => _TvSeriesScreenState();
}

class _TvSeriesScreenState extends State<TvSeriesScreen> {
  List<Category> _categories = [];
  Map<int, List<TvSeries>> _categorySeries = {};
  bool _isLoading = true;
  TvSeries? _featuredSeries;

  @override
  void initState() {
    super.initState();
    _loadData();
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
          (series) => series.tmdbId != null && series.tmdbId!.isNotEmpty,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return const Center(child: Text('No TV series found'));
    }

    return ListView(
      children: [
        // Featured Series - Netflix style
        if (_featuredSeries != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: FeaturedContent(
              title: _featuredSeries!.name,
              description: _featuredSeries!.description,
              tmdbId: _featuredSeries!.tmdbId,
              fallbackImageUrl: _featuredSeries!.coverUrl,
              year: _featuredSeries!.year,
              rating: _featuredSeries!.rating,
              isMovie: false,
              onTap: () => _navigateToSeries(_featuredSeries!),
            ),
          ),

        // Category Carousels
        ..._categories.map((category) {
          final seriesList = _categorySeries[category.id] ?? [];
          if (seriesList.isEmpty) {
            return const SizedBox.shrink();
          }

          return ContentCarousel<TvSeries>(
            title: category.name,
            items: seriesList,
            itemBuilder:
                (series) => TvSeriesCard(
                  series: series,
                  onTap: () => _navigateToSeries(series),
                ),
            onSeeAllPressed: () => _navigateToSeeAll(category, seriesList),
          );
        }),

        // Add some padding at the bottom
        const SizedBox(height: 20),
      ],
    );
  }
}
