import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:meta/meta.dart';

import 'get_initialized_mamoto_tracker.dart';

/// Used to test [MatomoTracker] initializations.
@isTest
void testInitialization(
  String description,
  List<void Function(MatomoTracker tracker, DateTime fixedDateTime)>
      expectations, {
  void Function()? init,
  String? contentBaseUrl,
  String? tokenAuth,
}) {
  test(description, () async {
    init?.call();

    final fixedDateTime = DateTime(2022);

    await withClock(Clock.fixed(fixedDateTime), () async {
      final matomoTracker = await getInitializedMatomoTracker(
        contentBaseUrl: contentBaseUrl,
        tokenAuth: tokenAuth,
      );

      for (final expectation in expectations) {
        expectation(matomoTracker, fixedDateTime);
      }
    });
  });
}
