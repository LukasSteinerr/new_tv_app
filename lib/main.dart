import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/objectbox_service.dart';
import 'services/playlist_service.dart';
import 'screens/home_screen.dart';
import 'constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ObjectBox
  final objectBoxService = await ObjectBoxService.create();
  final playlistService = PlaylistService(objectBoxService);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(MyApp(playlistService: playlistService));
}

class MyApp extends StatelessWidget {
  final PlaylistService playlistService;

  const MyApp({super.key, required this.playlistService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPTV Player',
      theme: AppTheme.darkTheme, // Use Netflix-style dark theme
      darkTheme: AppTheme.darkTheme, // Use Netflix-style dark theme
      themeMode: ThemeMode.dark, // Always use dark theme like Netflix
      home: HomeScreen(playlistService: playlistService),
    );
  }
}
