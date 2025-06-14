// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv/main.dart';
import 'package:tv/services/playlist_service.dart';

// Import models
import 'package:tv/models/playlist.dart';
import 'package:tv/models/channel.dart';
import 'package:tv/models/category.dart';
import 'package:tv/models/movie.dart';
import 'package:tv/models/tv_series.dart';
import 'package:tv/models/tv_episode.dart';
import 'package:tv/models/tv_program.dart'; // Import TvProgram

// Create a simple mock class for PlaylistService
class MockPlaylistService implements PlaylistService {
  @override
  Future<List<Playlist>> getAllPlaylists() async => [];

  @override
  Future<int> addPlaylist(Playlist playlist) async => 1;

  @override
  Future<bool> deletePlaylist(int id) async => true;

  @override
  Future<void> refreshPlaylist(Playlist playlist) async {}

  @override
  Future<List<Category>> getPlaylistCategories(int playlistId) async => [];

  @override
  Future<List<Channel>> getPlaylistChannels(int playlistId) async => [];

  @override
  Future<List<Channel>> getCategoryChannels(int categoryId) async => [];

  @override
  Future<List<Movie>> getPlaylistMovies(int playlistId) async => [];

  @override
  Future<List<Movie>> getCategoryMovies(int categoryId) async => [];

  @override
  Future<List<TvSeries>> getPlaylistTvSeries(int playlistId) async => [];

  @override
  Future<List<TvSeries>> getCategoryTvSeries(int categoryId) async => [];

  @override
  Future<List<TvEpisode>> getTvSeriesEpisodes(TvSeries series) async => [];

  @override
  Future<List<TvProgram>> getTvProgramsForChannel(String channelEpgId) async =>
      [];

  @override
  Future<List<TvProgram>> getTvProgramsForChannelInTimeRange(
    String channelEpgId,
    DateTime startTime,
    DateTime endTime,
  ) async => [];

  @override
  Future<List<Movie>> getFeaturedMovies(int playlistId) async => [];

  @override
  Future<void> refreshFeaturedMovies(int playlistId) async {}

  @override
  Future<List<TvSeries>> getFeaturedTvSeries(int playlistId) async => [];

  @override
  Future<void> refreshFeaturedTvSeries(int playlistId) async {}
}

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Create a mock playlist service
    final mockPlaylistService = MockPlaylistService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(playlistService: mockPlaylistService));

    // Just verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
