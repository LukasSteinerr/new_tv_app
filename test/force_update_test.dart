import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:force_update_helper/force_update_helper.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tv/router/app_router.dart';
import 'package:tv/services/analytics_service.dart';
import 'package:tv/services/playlist_service.dart';

// Mocks
class MockPlaylistService extends Mock implements PlaylistService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// A fake implementation of ForceUpdateClient for testing purposes.
class FakeForceUpdateClient implements ForceUpdateClient {
  final String requiredVersionValue;
  @override
  final String currentVersion;

  FakeForceUpdateClient({
    required this.requiredVersionValue,
    this.currentVersion = '1.0.0',
  });

  @override
  Future<String> Function() get fetchRequiredVersion =>
      () => Future.value(requiredVersionValue);

  @override
  String get iosAppStoreId => '12345';

  @override
  Future<bool> isAppUpdateRequired() async {
    final requiredVersion = await fetchRequiredVersion();
    // A simple string comparison is sufficient for this test.
    return requiredVersion.compareTo(currentVersion) > 0;
  }

  @override
  Future<String?> storeUrl() async => 'https://fake.store/url';

  @override
  TargetPlatform get platform => TargetPlatform.android;
}

void main() {
  // Set mock initial values for package_info_plus
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'tv',
      packageName: 'com.example.tv',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('ForceUpdateWidget', () {
    late AppRouter appRouter;
    late MockPlaylistService mockPlaylistService;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockPlaylistService = MockPlaylistService();
      mockAnalyticsService = MockAnalyticsService();
      appRouter = AppRouter(
        playlistService: mockPlaylistService,
        analyticsService: mockAnalyticsService,
      );
    });

    Future<void> pumpWidgetTree({
      required WidgetTester tester,
      required ForceUpdateClient forceUpdateClient,
      bool allowCancel = false,
      Future<void> Function(Uri)? showStoreListingCallback,
    }) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: ForceUpdateWidget(
              navigatorKey: navigatorKey,
              forceUpdateClient: forceUpdateClient,
              allowCancel: allowCancel,
              child: const SizedBox(), // A simple child
              showForceUpdateAlert:
                  (context, allowCancel) => showDialog(
                    context: context,
                    barrierDismissible: allowCancel,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Update Required'),
                          content: const Text(
                            'Please update the app to continue.',
                          ),
                          actions: [
                            if (allowCancel)
                              TextButton(
                                child: const Text('Later'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            TextButton(
                              child: const Text('Update Now'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        ),
                  ),
              showStoreListing: showStoreListingCallback ?? (_) async {},
              onException: (e, st) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows update dialog when required version is higher', (
      WidgetTester tester,
    ) async {
      final fakeForceUpdateClient = FakeForceUpdateClient(
        requiredVersionValue: '2.0.0',
      );

      await pumpWidgetTree(
        tester: tester,
        forceUpdateClient: fakeForceUpdateClient,
      );

      expect(find.text('Update Required'), findsOneWidget);
    });

    testWidgets('does not show update dialog when version is current', (
      WidgetTester tester,
    ) async {
      final fakeForceUpdateClient = FakeForceUpdateClient(
        requiredVersionValue: '1.0.0',
      );

      await pumpWidgetTree(
        tester: tester,
        forceUpdateClient: fakeForceUpdateClient,
      );

      expect(find.text('Update Required'), findsNothing);
    });

    testWidgets('shows "Later" button when allowCancel is true', (
      WidgetTester tester,
    ) async {
      final fakeForceUpdateClient = FakeForceUpdateClient(
        requiredVersionValue: '2.0.0',
      );

      await pumpWidgetTree(
        tester: tester,
        forceUpdateClient: fakeForceUpdateClient,
        allowCancel: true,
      );

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('does not show "Later" button when allowCancel is false', (
      WidgetTester tester,
    ) async {
      final fakeForceUpdateClient = FakeForceUpdateClient(
        requiredVersionValue: '2.0.0',
      );

      await pumpWidgetTree(
        tester: tester,
        forceUpdateClient: fakeForceUpdateClient,
        allowCancel: false,
      );

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('calls showStoreListing when "Update Now" is tapped', (
      WidgetTester tester,
    ) async {
      final fakeForceUpdateClient = FakeForceUpdateClient(
        requiredVersionValue: '2.0.0',
      );
      var showStoreListingCalled = false;

      await pumpWidgetTree(
        tester: tester,
        forceUpdateClient: fakeForceUpdateClient,
        showStoreListingCallback: (_) async {
          showStoreListingCalled = true;
        },
      );

      expect(find.text('Update Required'), findsOneWidget);

      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(showStoreListingCalled, isTrue);
    });
  });
}
