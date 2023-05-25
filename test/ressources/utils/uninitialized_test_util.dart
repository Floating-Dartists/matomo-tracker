import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/exceptions.dart';
import 'package:matomo_tracker/src/matomo.dart';
import 'package:meta/meta.dart';

typedef TrackerCallback = Future<void> Function(MatomoTracker tracker);

/// A test that expects the [callback] to throw an
/// [UninitializedMatomoInstanceException].
@isTest
void uninitializedTest(TrackerCallback callback) {
  test(
    'should throw UninitializedMatomoInstanceException if not initialized',
    () async {
      final matomoTracker = MatomoTracker();

      await expectLater(
        () async => callback(matomoTracker),
        throwsA(isA<UninitializedMatomoInstanceException>()),
      );
    },
  );
}
