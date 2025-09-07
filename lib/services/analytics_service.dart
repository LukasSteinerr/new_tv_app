import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Method to log a custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // Event for when a user attempts to add a playlist
  Future<void> logPlaylistAddAttempt({required String playlistType}) async {
    await logEvent(
      'playlist_add_attempt',
      parameters: {'playlist_type': playlistType},
    );
  }

  // Event for when a user successfully adds a playlist
  Future<void> logPlaylistAddSuccess({required String playlistType}) async {
    await logEvent(
      'playlist_add_success',
      parameters: {'playlist_type': playlistType},
    );
  }

  // Event for when a user fails to add a playlist
  Future<void> logPlaylistAddFailed({
    required String playlistType,
    String? reason,
  }) async {
    await logEvent(
      'playlist_add_failed',
      parameters: {
        'playlist_type': playlistType,
        'reason': reason ?? 'unknown',
      },
    );
  }

  // Event for when a user hits a paywall
  Future<void> logHitPaywall() async {
    await logEvent('hit_paywall');
  }

  // Event for when a user starts a subscription
  Future<void> logSubscriptionStarted() async {
    await logEvent('subscription_started');
  }
}
