import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../ressources/mock/data.dart';
import '../ressources/mock/mock.dart';
import '../ressources/utils/get_initialized_mamoto_tracker.dart';
import '../ressources/utils/matomo_tracker_setup.dart';

void main() {
  group('Cookieless', () {
    setUp(matomoTrackerSetup);

    test('activate cookieless clears VisitorId', () async {
      // cookieless is off by default
      final tracker = await getInitializedMatomoTracker(
        visitorId: matomoTrackerVisitorId,
      );
      expect(tracker.visitor.id, isNotNull);

      await tracker.setCookieless(cookieless: true);
      expect(tracker.visitor.id, isNull);
    });

    test('deactivate cookieless initializes VisitorId', () async {
      when(mockLocalStorage.getVisitorId)
          .thenAnswer((_) async => matomoTrackerVisitorId);

      final tracker = await getInitializedMatomoTracker(
        cookieless: true,
      );
      expect(tracker.visitor.id, isNull);

      await tracker.setCookieless(
        cookieless: false,
        localStorage: mockLocalStorage,
      );
      expect(tracker.visitor.id, isNotNull);
    });
  });
}
