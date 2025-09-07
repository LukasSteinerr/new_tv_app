import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/channel.dart';
import '../models/movie.dart';
import '../models/playlist.dart';
import '../models/tv_episode.dart';
import '../models/tv_series.dart';
import '../screens/add_playlist_screen.dart';
import '../screens/all_actors_screen.dart';
import '../screens/category_channels_screen.dart';
import '../screens/category_content_screen.dart';
import '../screens/channel_epg_guide_screen.dart';
import '../screens/download_screen.dart';
import '../screens/home_screen.dart';
import '../screens/live_tv_screen.dart';
import '../screens/movies_screen.dart';
import '../screens/my_list_screen.dart';
import '../screens/netflix_style_movie_detail_screen.dart';
import '../screens/netflix_style_tv_series_detail_screen.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tv_series_screen.dart';
import '../screens/universal_video_player.dart';
import '../screens/xtream_playlist_screen.dart';
import '../services/analytics_service.dart';
import '../services/playlist_service.dart';

class AppRouter {
  final PlaylistService playlistService;
  final AnalyticsService analyticsService;

  AppRouter({required this.playlistService, required this.analyticsService});

  late final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder:
            (context, state) => HomeScreen(playlistService: playlistService),
      ),
      GoRoute(
        path: '/add-playlist',
        builder: (context, state) {
          final playlist = state.extra as Playlist?;
          return AddPlaylistScreen(
            playlistService: playlistService,
            analyticsService: analyticsService,
            playlist: playlist,
          );
        },
      ),
      GoRoute(
        path: '/playlist-detail',
        builder: (context, state) {
          final playlist = state.extra as Playlist;
          return PlaylistDetailScreen(
            playlistService: playlistService,
            analyticsService: analyticsService,
            playlist: playlist,
          );
        },
      ),
      GoRoute(
        path: '/xtream-playlist',
        builder: (context, state) {
          final playlist = state.extra as Playlist;
          return XtreamPlaylistScreen(
            playlistService: playlistService,
            analyticsService: analyticsService,
            playlist: playlist,
          );
        },
      ),
      GoRoute(
        path: '/category-channels',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final category = args['category'] as Category;
          final channels = args['channels'] as List<Channel>;
          return CategoryChannelsScreen(category: category, channels: channels);
        },
      ),
      GoRoute(
        path: '/video-player',
        builder: (context, state) {
          if (state.extra is Channel) {
            return UniversalVideoPlayer(channel: state.extra as Channel);
          } else if (state.extra is Movie) {
            return UniversalVideoPlayer(movie: state.extra as Movie);
          } else if (state.extra is TvEpisode) {
            return UniversalVideoPlayer(episode: state.extra as TvEpisode);
          } else if (state.extra is Map<String, dynamic>) {
            final args = state.extra as Map<String, dynamic>;
            if (args.containsKey('movie')) {
              return UniversalVideoPlayer(
                movie: args['movie'] as Movie,
                localPath: args['localPath'] as String?,
              );
            } else if (args.containsKey('episode')) {
              return UniversalVideoPlayer(
                episode: args['episode'] as TvEpisode,
                localPath: args['localPath'] as String?,
              );
            }
          }
          // You might want to return an error page or a default state
          return const Scaffold(
            body: Center(child: Text('Error: Invalid video type')),
          );
        },
      ),
      GoRoute(
        path: '/movie-detail',
        builder: (context, state) {
          final movie = state.extra as Movie;
          return NetflixStyleMovieDetailScreen(movie: movie);
        },
      ),
      GoRoute(
        path: '/category-content',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final category = args['category'] as Category;
          final items = args['items'] as List;
          final playlistService = args['playlistService'] as PlaylistService;
          return CategoryContentScreen(
            category: category,
            items: items,
            playlistService: playlistService,
          );
        },
      ),
      GoRoute(
        path: '/tv-series-detail',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final series = args['series'] as TvSeries;
          final playlistService = args['playlistService'] as PlaylistService;
          return NetflixStyleTvSeriesDetailScreen(
            series: series,
            playlistService: playlistService,
          );
        },
      ),
      GoRoute(
        path: '/channel-epg-guide',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final channel = args['channel'] as Channel;
          final playlistService = args['playlistService'] as PlaylistService;
          return ChannelEpgGuideScreen(
            channel: channel,
            playlistService: playlistService,
          );
        },
      ),
      GoRoute(
        path: '/all-actors',
        builder: (context, state) {
          final movie = state.extra as Movie;
          return AllActorsScreen(movie: movie);
        },
      ),
    ],
  );
}
