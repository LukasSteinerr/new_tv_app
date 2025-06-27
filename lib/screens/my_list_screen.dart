import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/tv_series.dart';
import '../services/objectbox_service.dart';
import 'netflix_style_movie_detail_screen.dart';
import 'netflix_style_tv_series_detail_screen.dart';
import '../services/playlist_service.dart';

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

  List<dynamic> _getCurrentList() {
    switch (_tabController.index) {
      case 0:
        return [..._myMovies, ..._mySeries];
      case 1:
        return _myMovies;
      case 2:
        return _mySeries;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _isLoading ? [] : _getCurrentList();
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
              : currentList.isEmpty
              ? const Center(
                child: Text(
                  'Your list is empty.',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildGrid(currentList), // All
                  _buildGrid(_myMovies), // Movies
                  _buildGrid(_mySeries), // TV Shows
                ],
              ),
    );
  }

  Widget _buildGrid(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Nothing in this section.',
          style: TextStyle(color: Colors.white70),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => NetflixStyleMovieDetailScreen(movie: item),
                ),
              ).then((_) => _loadMyList());
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: item.posterUrl ?? item.coverUrl ?? '',
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.white),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.white),
                    ),
              ),
            ),
          );
        } else if (item is TvSeries) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => NetflixStyleTvSeriesDetailScreen(
                        series: item,
                        playlistService: widget.playlistService,
                      ),
                ),
              ).then((_) => _loadMyList());
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: item.coverUrl ?? '',
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.tv, color: Colors.white),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.tv, color: Colors.white),
                    ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
