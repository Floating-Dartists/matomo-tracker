import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_ressources/mock/data.dart';
import '../../test_ressources/utils/get_initialized_mamoto_tracker.dart';
import '../../test_ressources/utils/matomo_tracker_setup.dart';

void main() {
  setUpAll(matomoTrackerSetup);

  // this test should be the first one to launch, because once the MatomoTracker
  // is initialized, it will not be possible reinitialize it
  test('it should throw AssertionError if we initialize with wrong visitorId',
      () async {
    await expectLater(
      () => getInitializedMatomoTracker(
        visitorId: matomoTrackerWrongVisitorId,
      ),
      throwsAssertionError,
    );
  });

  test('it should be able to initialize', () async {
    final fixedDateTime = DateTime(2022);

    await withClock(Clock.fixed(fixedDateTime), () async {
      final matomoTracker = await getInitializedMatomoTracker();

      expect(matomoTracker.url, matomoTrackerUrl);
      expect(matomoTracker.siteId, matomoTrackerSiteId);
      expect(matomoTracker.initialized, true);
      expect(matomoTracker.timer.isActive, true);
      expect(matomoTracker.session.firstVisit, fixedDateTime.toUtc());
      expect(matomoTracker.session.lastVisit, fixedDateTime.toUtc());
      expect(matomoTracker.session.visitCount, 1);
    });
  });

  test('it should be able to set opt out', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    await matomoTracker.setOptOut(optout: true);

    verify(() => mockSharedPreferences.setBool(MatomoTracker.kOptOut, true))
        .called(1);
  });

  test('it should be able to get optOut', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    matomoTracker.getOptOut();

    verify(() => mockSharedPreferences.getBool(MatomoTracker.kOptOut))
        .called(1);
  });

  test('it should be able to clear localData', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    matomoTracker.clear();

    verify(() => mockSharedPreferences.remove(MatomoTracker.kFirstVisit))
        .called(1);
    verify(() => mockSharedPreferences.remove(MatomoTracker.kVisitCount))
        .called(1);
    verify(() => mockSharedPreferences.remove(MatomoTracker.kVisitorId))
        .called(1);
  });

  test('it should be able to dispose', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    matomoTracker.dispose();

    expect(matomoTracker.timer.isActive, false);
  });

  test('it should be able to pause', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    matomoTracker.pause();

    expect(matomoTracker.timer.isActive, false);
  });

  test('it should be able to resume', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    matomoTracker.pause();
    matomoTracker.resume();

    expect(matomoTracker.timer.isActive, true);
  });

  test('it should be able to dispatchEvents', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    final queueLength = matomoTracker.queue.length;

    matomoTracker.trackDimensions(matomoTrackerDimensions);
    expect(matomoTracker.queue.length, queueLength + 1);
    matomoTracker.dispatchEvents();
    expect(matomoTracker.queue.length, 0);
  });

  testTracking('it should be able to trackScreen', (tracker) {
    when(() => mockBuildContext.widget).thenReturn(matomoTrackerMockWidget);

    tracker.trackScreen(
      mockBuildContext,
      eventName: matomoTrackerEvenName,
    );
  });

  testTracking('it should be able to trackScreenWithName', (tracker) async {
    tracker.trackScreenWithName(
      widgetName: matomoTrackerMockWidget.toStringShort(),
      eventName: matomoTrackerEvenName,
    );
  });

  testTracking('it should be able to trackGoal', (tracker) async {
    tracker.trackGoal(
      matomoTrackerGoalId,
    );
  });

  testTracking('it should be able to trackEvent', (tracker) async {
    tracker.trackEvent(
      eventCategory: matomoTrackerEventCategory,
      action: matomoTrackerAction,
    );
  });

  testTracking('it should be able to trackDimensions', (tracker) async {
    tracker.trackDimensions(
      matomoTrackerDimensions,
    );
  });

  testTracking('it should be able to trackSearch', (tracker) async {
    tracker.trackSearch(
      searchKeyword: matomoTrackerSearchKeyword,
    );
  });

  testTracking('it should be able to trackCartUpdate', (tracker) async {
    tracker.trackCartUpdate([], null, null, null, null);
  });

  testTracking('it should be able to trackOrder', (tracker) async {
    tracker.trackOrder(null, [], null, null, null, null, null);
  });

  testTracking('it should be able to trackOutlink', (tracker) async {
    tracker.trackOutlink(null);
  });
}

@isTest
Future<void> testTracking(
  String description,
  void Function(MatomoTracker tracker) trackFunction,
) async {
  test(description, () async {
    final matomoTracker = await getInitializedMatomoTracker();
    final queueLength = matomoTracker.queue.length;
    trackFunction(matomoTracker);

    expect(matomoTracker.queue.length, queueLength + 1);
  });
}
