import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:meta/meta.dart';

import 'get_initialized_mamoto_tracker.dart';

/// Used to test [MatomoTracker] tracking logic.
@isTest
void testTracking(
  String description,
  void Function(MatomoTracker tracker) trackFunction, {
  void Function(MatomoTracker tracker)? extraExpectations,
}) {
  test(description, () async {
    final matomoTracker = await getInitializedMatomoTracker();
    final queueLength = matomoTracker.queue.length;
    trackFunction(matomoTracker);

    expect(matomoTracker.queue.length, queueLength + 1);

    extraExpectations?.call(matomoTracker);
  });
}
