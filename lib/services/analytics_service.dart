import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Method to log a custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // Event for when a user attempts to add a playlist
  Future<void> logPlaylistAddAttempt() async {
    await logEvent('playlist_add_attempt');
  }

  // Event for when a user successfully adds a playlist
  Future<void> logPlaylistAddSuccess() async {
    await logEvent('playlist_add_success');
  }

  // Event for when a user fails to add a playlist
  Future<void> logPlaylistAddFailed({String? reason}) async {
    await logEvent(
      'playlist_add_failed',
      parameters: {'reason': reason ?? 'unknown'},
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
