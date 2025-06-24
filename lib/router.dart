import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/playlist_service.dart';
import 'models/playlist.dart';
import 'models/movie.dart';
import 'models/tv_series.dart';
import 'models/channel.dart';
import 'models/category.dart';
import 'models/tv_episode.dart';
import 'screens/home_screen.dart';
import 'screens/add_playlist_screen.dart';
import 'screens/playlist_detail_screen.dart';
import 'screens/xtream_playlist_screen.dart';
import 'screens/netflix_style_movie_detail_screen.dart';
import 'screens/netflix_style_tv_series_detail_screen.dart';
import 'screens/universal_video_player.dart';
import 'screens/category_content_screen.dart';
import 'screens/playlist_detail_screen.dart'
    as playlist_detail
    show CategoryChannelsScreen;
import 'screens/channel_epg_guide_screen.dart';
import 'screens/my_list_screen.dart';
import 'screens/all_actors_screen.dart';
import 'screens/download_screen.dart';

class AppRouter {
  static GoRouter createRouter(PlaylistService playlistService) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        // Home screen - lists all playlists
        GoRoute(
          path: '/',
          builder:
              (context, state) => HomeScreen(playlistService: playlistService),
        ),

        // Add playlist screen
        GoRoute(
          path: '/add-playlist',
          builder: (context, state) {
            final playlistJson = state.uri.queryParameters['playlist'];
            Playlist? playlist;
            if (playlistJson != null) {
              // Parse playlist from query parameter if editing
              // This would need proper JSON parsing in real implementation
            }
            return AddPlaylistScreen(
              playlistService: playlistService,
              playlist: playlist,
            );
          },
        ),

        // Playlist detail screen (M3U playlists)
        GoRoute(
          path: '/playlist/:playlistId',
          builder: (context, state) {
            final playlistId = int.parse(state.pathParameters['playlistId']!);
            return FutureBuilder<List<Playlist>>(
              future: playlistService.getAllPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final playlist = snapshot.data?.firstWhere(
                  (p) => p.id == playlistId,
                );
                if (playlist == null) {
                  return const Scaffold(
                    body: Center(child: Text('Playlist not found')),
                  );
                }
                return PlaylistDetailScreen(
                  playlistService: playlistService,
                  playlist: playlist,
                );
              },
            );
          },
        ),

        // Xtream playlist screen with tabs
        GoRoute(
          path: '/xtream/:playlistId',
          builder: (context, state) {
            final playlistId = int.parse(state.pathParameters['playlistId']!);
            final tabIndex =
                int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
            return FutureBuilder<List<Playlist>>(
              future: playlistService.getAllPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final playlist = snapshot.data?.firstWhere(
                  (p) => p.id == playlistId,
                );
                if (playlist == null) {
                  return const Scaffold(
                    body: Center(child: Text('Playlist not found')),
                  );
                }
                return XtreamPlaylistScreen(
                  playlistService: playlistService,
                  playlist: playlist,
                  initialTabIndex: tabIndex,
                );
              },
            );
          },
        ),

        // Movie detail screen
        GoRoute(
          path: '/movie/:movieId',
          builder: (context, state) {
            final movie = state.extra as Movie?;
            if (movie == null) {
              return const Scaffold(
                body: Center(child: Text('Movie data not found')),
              );
            }
            return NetflixStyleMovieDetailScreen(movie: movie);
          },
        ),

        // TV Series detail screen
        GoRoute(
          path: '/series/:seriesId',
          builder: (context, state) {
            final series = state.extra as TvSeries?;
            if (series == null) {
              return const Scaffold(
                body: Center(child: Text('Series data not found')),
              );
            }
            return NetflixStyleTvSeriesDetailScreen(
              series: series,
              playlistService: playlistService,
            );
          },
        ),

        // Video player screen
        GoRoute(
          path: '/player',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is Channel) {
              return UniversalVideoPlayer(channel: extra);
            } else if (extra is TvEpisode) {
              return UniversalVideoPlayer(episode: extra);
            } else if (extra is Movie) {
              return UniversalVideoPlayer(movie: extra);
            }

            return const Scaffold(
              body: Center(child: Text('No media to play')),
            );
          },
        ),

        // Category content screen
        GoRoute(
          path: '/category/:categoryId',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;

            if (extra == null) {
              return const Scaffold(
                body: Center(child: Text('Category data not found')),
              );
            }
            final category = extra['category'] as Category;
            final items = extra['items'] as List<dynamic>;

            // In real implementation, you would fetch items by category ID
            return CategoryContentScreen(
              category: category,
              items: items, // This would be populated from the route
              playlistService: playlistService,
            );
          },
        ),

        // Category channels screen
        GoRoute(
          path: '/category-channels/:categoryId',
          builder: (context, state) {
            final categoryData = state.extra as Map<String, dynamic>?;

            if (categoryData == null) {
              return const Scaffold(
                body: Center(child: Text('Category not found')),
              );
            }

            return playlist_detail.CategoryChannelsScreen(
              category: categoryData['category'] as Category,
              channels: categoryData['channels'] as List<Channel>,
            );
          },
        ),

        // EPG Guide screen
        GoRoute(
          path: '/epg/:channelId',
          builder: (context, state) {
            final channel = state.extra as Channel?;

            if (channel == null) {
              return const Scaffold(
                body: Center(child: Text('Channel not found')),
              );
            }

            return ChannelEpgGuideScreen(
              channel: channel,
              playlistService: playlistService,
            );
          },
        ),

        // My List screen
        GoRoute(
          path: '/my-list/:playlistId',
          builder: (context, state) {
            return MyListScreen(playlistService: playlistService);
          },
        ),

        // All actors screen
        GoRoute(
          path: '/actors',
          builder: (context, state) {
            final movie = state.extra as Movie?;
            if (movie == null) {
              return const Scaffold(
                body: Center(child: Text('Movie data not found')),
              );
            }
            return AllActorsScreen(movie: movie);
          },
        ),

        // Download screen
        GoRoute(
          path: '/downloads',
          builder: (context, state) {
            return const DownloadScreen();
          },
        ),
      ],
    );
  }
}
