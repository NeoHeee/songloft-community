import 'package:flutter_test/flutter_test.dart';
import 'package:songloft_flutter/core/navigation/mobile_back_policy.dart';

void main() {
  group('MobileBackPolicy', () {
    test('maps nested routes to deterministic parent pages', () {
      expect(
        MobileBackPolicy.parentRouteFor('/playlists/42'),
        MobileBackPolicy.playlists,
      );
      expect(
        MobileBackPolicy.parentRouteFor('/settings/servers'),
        MobileBackPolicy.settings,
      );
      expect(
        MobileBackPolicy.parentRouteFor('/settings/duplicate-check'),
        MobileBackPolicy.settings,
      );
    });

    test('does not treat primary sections as nested routes', () {
      expect(MobileBackPolicy.parentRouteFor('/'), isNull);
      expect(MobileBackPolicy.parentRouteFor('/library'), isNull);
      expect(MobileBackPolicy.parentRouteFor('/playlists'), isNull);
      expect(MobileBackPolicy.parentRouteFor('/settings'), isNull);
    });

    test('recognizes primary mobile sections', () {
      expect(MobileBackPolicy.isPrimarySection('/library'), isTrue);
      expect(MobileBackPolicy.isPrimarySection('/playlists'), isTrue);
      expect(MobileBackPolicy.isPrimarySection('/settings'), isTrue);
      expect(MobileBackPolicy.isPrimarySection('/plugin-tab/search'), isTrue);
      expect(MobileBackPolicy.isPrimarySection('/playlists/42'), isFalse);
    });
  });

  group('MobileExitTracker', () {
    test('requires two presses inside the confirmation window', () {
      final tracker = MobileExitTracker();
      final first = DateTime(2026, 7, 12, 12);

      expect(tracker.shouldExit(first), isFalse);
      expect(
        tracker.shouldExit(first.add(const Duration(milliseconds: 1500))),
        isTrue,
      );
    });

    test('resets after the confirmation window or explicit reset', () {
      final tracker = MobileExitTracker();
      final first = DateTime(2026, 7, 12, 12);

      expect(tracker.shouldExit(first), isFalse);
      expect(tracker.shouldExit(first.add(const Duration(seconds: 3))), isFalse);
      tracker.reset();
      expect(
        tracker.shouldExit(first.add(const Duration(seconds: 4))),
        isFalse,
      );
    });
  });
}
