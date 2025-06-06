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

class _MyListScreenState extends State<MyListScreen> {
  late final ObjectBoxService _objectBoxService;
  List<dynamic> _myList = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _objectBoxService = await ObjectBoxService.create();
    _loadMyList();
  }

  void _loadMyList() {
    final movies =
        _objectBoxService.getAllMovies().where((m) => m.myList == 1).toList();
    final series =
        _objectBoxService.getAllTvSeries().where((s) => s.myList == 1).toList();
    setState(() {
      if (_selectedFilter == 'All') {
        _myList = [...movies, ...series];
      } else if (_selectedFilter == 'Movies') {
        _myList = movies;
      } else {
        _myList = series;
      }
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: [
                _selectedFilter == 'All',
                _selectedFilter == 'Movies',
                _selectedFilter == 'TV Shows',
              ],
              onPressed: (index) {
                setState(() {
                  if (index == 0) {
                    _selectedFilter = 'All';
                  } else if (index == 1) {
                    _selectedFilter = 'Movies';
                  } else {
                    _selectedFilter = 'TV Shows';
                  }
                  _loadMyList();
                });
              },
              color: Colors.white,
              selectedColor: Colors.black,
              fillColor: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('All'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Movies'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('TV Shows'),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _myList.isEmpty
                    ? const Center(
                      child: Text(
                        'Your list is empty.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 2 / 3,
                          ),
                      itemCount: _myList.length,
                      itemBuilder: (context, index) {
                        final item = _myList[index];
                        if (item is Movie) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          NetflixStyleMovieDetailScreen(
                                            movie: item,
                                          ),
                                ),
                              ).then((_) => _loadMyList());
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item.posterUrl ?? item.coverUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.movie,
                                      color: Colors.white,
                                    ),
                                  );
                                },
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
                                      (context) =>
                                          NetflixStyleTvSeriesDetailScreen(
                                            series: item,
                                            playlistService:
                                                widget.playlistService,
                                          ),
                                ),
                              ).then((_) => _loadMyList());
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item.coverUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.tv,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
