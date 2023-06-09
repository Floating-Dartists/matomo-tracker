import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

import '../ressources/utils/get_initialized_mamoto_tracker.dart';
import '../ressources/utils/matomo_tracker_setup.dart';
import '../ressources/utils/testable_app.dart';

void main() {
  late final MatomoTracker matomoTracker;

  setUpAll(() async {
    matomoTrackerSetup();
    matomoTracker =
        await getInitializedMatomoTracker(shouldForceCreation: false);
  });

  testWidgets('it should be able to track widget', (tester) async {
    final queueLength = matomoTracker.queue.length;

    await tester.pumpWidget(
      const TestableApp(
        child: TraceableWidget(
          actionName: 'test',
          child: SizedBox(),
        ),
      ),
    );

    final traceableWidgetFinder = find.byType(TraceableWidget);

    expect(traceableWidgetFinder, findsOneWidget);
    expect(matomoTracker.queue.length, queueLength + 1);
  });
}
