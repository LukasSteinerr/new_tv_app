import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../services/objectbox_service.dart';
import 'netflix_style_movie_detail_screen.dart';
import 'netflix_style_tv_series_detail_screen.dart';
import '../services/playlist_service.dart';
import '../widgets/tmdb_image.dart';

class MyListScreen extends StatefulWidget {
  final PlaylistService playlistService;
  const MyListScreen({super.key, required this.playlistService});

  @override
  _MyListScreenState createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen>
    with SingleTickerProviderStateMixin {
  late final ObjectBoxService _objectBoxService;
  List<Movie> _myMovies = [];
  List<TvSeries> _mySeries = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      // Re-renders the UI to show the correct list based on the selected tab
    });
  }

  Future<void> _initializeServices() async {
    _objectBoxService = await ObjectBoxService.create();
    _loadMyList();
  }

  void _loadMyList() {
    setState(() {
      _myMovies =
          _objectBoxService.getAllMovies().where((m) => m.myList == 1).toList();
      _mySeries =
          _objectBoxService
              .getAllTvSeries()
              .where((s) => s.myList == 1)
              .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My List'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'All (${_myMovies.length + _mySeries.length})'),
            Tab(text: 'Movies (${_myMovies.length})'),
            Tab(text: 'TV Shows (${_mySeries.length})'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildGrid([..._myMovies, ..._mySeries]), // All
                  _buildGrid(_myMovies), // Movies
                  _buildGrid(_mySeries), // TV Shows
                ],
              ),
    );
  }

  Widget _buildGrid(List<dynamic> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: const Center(
          child: Text(
            'Nothing in this section.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 2 / 3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is Movie) {
          return GestureDetector(
            onTap: () {
              context
                  .push('/movie-detail', extra: item)
                  .then((_) => _loadMyList());
            },
            child: TMDBImage(
              tmdbId: item.tmdbId,
              fallbackUrl: item.coverUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              isMovie: true,
            ),
          );
        } else if (item is TvSeries) {
          return GestureDetector(
            onTap: () {
              context
                  .push(
                    '/tv-series-detail',
                    extra: {
                      'series': item,
                      'playlistService': widget.playlistService,
                    },
                  )
                  .then((_) => _loadMyList());
            },
            child: TMDBImage(
              tmdbId: item.tmdbId,
              fallbackUrl: item.coverUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              isMovie: false,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
