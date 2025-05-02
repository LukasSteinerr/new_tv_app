import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/tv_series.dart';
import '../models/category.dart';
import '../services/playlist_service.dart';
import '../widgets/content_carousel.dart';
import '../widgets/tv_series_card.dart';
import 'tv_series_detail_screen.dart';

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
      for (final category in seriesCategories) {
        final series = await widget.playlistService.getCategoryTvSeries(
          category.id,
        );
        categorySeriesMap[category.id] = series;
      }

      if (mounted) {
        setState(() {
          _categories = seriesCategories;
          _categorySeries = categorySeriesMap;
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
            (context) => TvSeriesDetailScreen(
              playlistService: widget.playlistService,
              series: series,
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
          );
        }),

        // Add some padding at the bottom
        const SizedBox(height: 20),
      ],
    );
  }
}
