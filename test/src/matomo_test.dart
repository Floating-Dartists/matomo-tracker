import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:mocktail/mocktail.dart';

import '../ressources/mock/data.dart';
import '../ressources/mock/mock.dart';
import '../ressources/utils/get_initialized_mamoto_tracker.dart';
import '../ressources/utils/matomo_tracker_initialization.dart';
import '../ressources/utils/matomo_tracker_setup.dart';
import '../ressources/utils/matomo_tracker_tracking.dart';
import '../ressources/utils/mock_platform_info.dart';

void main() {
  setUp(matomoTrackerSetup);

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

  group(
    'initialize',
    () {
      // We need to setup matomo tracker mock on each tests because we clear some
      // of the mocks used in the matomo tracker
      setUp(matomoTrackerSetup);

      tearDown(() {
        // We reset shared preferences to avoid side effects between tests
        reset(mockSharedPreferences);
      });
      testInitialization(
        'it should be able to initialize',
        [
          (tracker, _) => expect(tracker.url, matomoTrackerUrl),
          (tracker, _) => expect(tracker.siteId, matomoTrackerSiteId),
          (tracker, _) => expect(tracker.initialized, true),
          (tracker, _) => expect(tracker.timer.isActive, true),
          (tracker, fixedDateTime) =>
              expect(tracker.session.firstVisit, fixedDateTime.toUtc()),
          (tracker, fixedDateTime) =>
              expect(tracker.session.lastVisit, fixedDateTime.toUtc()),
          (tracker, _) => expect(tracker.session.visitCount, 1),
        ],
      );

      testInitialization(
        'it should be able to get localFirstVisit from local storage',
        init: () {
          when(
            () => mockSharedPreferences.getInt(MatomoTracker.kFirstVisit),
          ).thenReturn(matomoTrackerLocalFirstVisist);
        },
        [
          (tracker, fixedDateTime) => expect(
                tracker.session.firstVisit,
                DateTime.fromMillisecondsSinceEpoch(
                  matomoTrackerLocalFirstVisist,
                  isUtc: true,
                ),
              ),
        ],
      );

      testInitialization(
        'it should be able to get add a given contentBaseUrl',
        [
          (tracker, _) =>
              expect(tracker.contentBase, matomoTrackerContentBaseUrl),
        ],
        contentBaseUrl: matomoTrackerContentBaseUrl,
      );

      testInitialization(
        'it should be able to set tokenAuth',
        [(tracker, _) => expect(tracker.getAuthToken, matomoTrackerTokenAuth)],
        tokenAuth: matomoTrackerTokenAuth,
      );
    },
  );

  group('OptOut', () {
    test('it should be able to set opt out', () async {
      final matomoTracker = await getInitializedMatomoTracker();
      await matomoTracker.setOptOut(optout: true);

      verify(() => mockSharedPreferences.setBool(MatomoTracker.kOptOut, true));
      expect(matomoTracker.optOut, true);
    });

    test('it should be able to get optOut from local db', () async {
      final matomoTracker = await getInitializedMatomoTracker();
      matomoTracker.getOptOut();

      verify(() => mockSharedPreferences.getBool(MatomoTracker.kOptOut));
    });
  });

  group('lifecycle', () {
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
      matomoTracker
        ..pause()
        ..resume();
      expect(matomoTracker.timer.isActive, true);
    });

    test('it should be able to clear localData', () async {
      final matomoTracker = await getInitializedMatomoTracker();
      matomoTracker.clear();

      verify(() => mockSharedPreferences.remove(MatomoTracker.kFirstVisit));
      verify(() => mockSharedPreferences.remove(MatomoTracker.kVisitCount));
      verify(() => mockSharedPreferences.remove(MatomoTracker.kVisitorId));
    });
  });

  test('it should be able to dispatchEvents', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    final queueLength = matomoTracker.queue.length;

    matomoTracker.trackDimensions(matomoTrackerDimensions);
    expect(matomoTracker.queue.length, queueLength + 1);
    await matomoTracker.dispatchEvents();
    expect(matomoTracker.queue.length, 0);
  });

  group('tracking', () {
    testTracking(
      'it should be able to trackScreen',
      (tracker) {
        when(() => mockBuildContext.widget).thenReturn(matomoTrackerMockWidget);

        tracker.trackScreen(
          mockBuildContext,
          eventName: matomoTrackerEvenName,
        );
      },
    );

    testTracking(
      "it should be able to trackScreen and currentScreenId should change of it's given",
      (tracker) {
        when(() => mockBuildContext.widget).thenReturn(matomoTrackerMockWidget);

        tracker.trackScreen(
          mockBuildContext,
          eventName: matomoTrackerEvenName,
          currentScreenId: matomoTrackerCurrentScreenId,
        );
      },
      extraExpectations: (tracker) {
        expect(tracker.currentScreenId, matomoTrackerCurrentScreenId);
      },
    );

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
  });

  test('it should be able to set visitor userId', () async {
    final matomoTracker = await getInitializedMatomoTracker();
    matomoTracker.setVisitorUserId(userId);

    expect(matomoTracker.visitor.userId, userId);
  });

  group('userAgent', () {
    setUpAll(() {
      // Web
      when(() => mockDeviceInfoPlugin.webBrowserInfo)
          .thenAnswer((_) => Future.value(mockWebBrowserInfo));
      when(() => mockWebBrowserInfo.userAgent).thenReturn(webBrowserUserAgent);

      // Android
      when(() => mockDeviceInfoPlugin.androidInfo)
          .thenAnswer((_) => Future.value(mockAndroidDeviceInfo));
      when(() => mockAndroidDeviceInfo.version)
          .thenReturn(mockAndroidBuildVersion);
      when(() => mockAndroidBuildVersion.release).thenReturn(androidRelease);
      when(() => mockAndroidBuildVersion.sdkInt).thenReturn(androidSdkInt);
      when(() => mockAndroidDeviceInfo.manufacturer)
          .thenReturn(androidManufacturer);
      when(() => mockAndroidDeviceInfo.model).thenReturn(androidModel);

      // iOS
      when(() => mockDeviceInfoPlugin.iosInfo)
          .thenAnswer((_) => Future.value(mockIosDeviceInfo));
      when(() => mockIosDeviceInfo.systemName).thenReturn(iosSystemName);
      when(() => mockIosDeviceInfo.systemVersion).thenReturn(iosSystemVersion);
      when(() => mockIosDeviceInfo.model).thenReturn(iosModel);

      // Windows
      when(() => mockDeviceInfoPlugin.windowsInfo)
          .thenAnswer((_) => Future.value(mockWindowsDeviceInfo));
      when(() => mockWindowsDeviceInfo.releaseId).thenReturn(windowsReleaseId);
      when(() => mockWindowsDeviceInfo.buildNumber)
          .thenReturn(windowsBuildNumber);

      // MacOS
      when(() => mockDeviceInfoPlugin.macOsInfo)
          .thenAnswer((_) => Future.value(mockMacOsDeviceInfo));
      when(() => mockMacOsDeviceInfo.model).thenReturn(macOsModel);
      when(() => mockMacOsDeviceInfo.kernelVersion)
          .thenReturn(macOsKernelVersion);
      when(() => mockMacOsDeviceInfo.osRelease).thenReturn(macOsRelease);

      // Linux
      when(() => mockDeviceInfoPlugin.linuxInfo)
          .thenAnswer((_) => Future.value(mockLinuxDeviceInfo));
      when(() => mockLinuxDeviceInfo.prettyName).thenReturn(linuxPrettyName);
    });

    tearDown(() {
      reset(mockPlatformInfo);
    });

    test('it should be able to get userAgent for web platform', () async {
      setUpPlatformInfo(isWeb: true);

      final matomoTracker = await getInitializedMatomoTracker(
        platformInfo: mockPlatformInfo,
      );

      final userAgent = await matomoTracker.getUserAgent(
        deviceInfoPlugin: mockDeviceInfoPlugin,
      );

      expect(userAgent, webBrowserUserAgent);
    });

    test('it should be able to get userAgent for android platform', () async {
      setUpPlatformInfo(isAndroid: true);

      final matomoTracker = await getInitializedMatomoTracker(
        platformInfo: mockPlatformInfo,
      );

      final userAgent = await matomoTracker.getUserAgent(
        deviceInfoPlugin: mockDeviceInfoPlugin,
      );

      expect(
        userAgent,
        'Android $androidRelease (SDK $androidSdkInt), $androidManufacturer $androidModel',
      );
    });

    test('it should be able to get userAgent for iOS platform', () async {
      setUpPlatformInfo(isIOS: true);

      final matomoTracker = await getInitializedMatomoTracker(
        platformInfo: mockPlatformInfo,
      );

      final userAgent = await matomoTracker.getUserAgent(
        deviceInfoPlugin: mockDeviceInfoPlugin,
      );

      expect(
        userAgent,
        '$iosSystemName $iosSystemVersion, $iosModel',
      );
    });

    test('it should be able to get userAgent for Windows platform', () async {
      setUpPlatformInfo(isWindows: true);

      final matomoTracker = await getInitializedMatomoTracker(
        platformInfo: mockPlatformInfo,
      );

      final userAgent = await matomoTracker.getUserAgent(
        deviceInfoPlugin: mockDeviceInfoPlugin,
      );

      expect(
        userAgent,
        'Windows $windowsReleaseId.$windowsBuildNumber',
      );
    });

    test('it should be able to get userAgent for MacOs platform', () async {
      setUpPlatformInfo(isMacOS: true);

      final matomoTracker = await getInitializedMatomoTracker(
        platformInfo: mockPlatformInfo,
      );

      final userAgent = await matomoTracker.getUserAgent(
        deviceInfoPlugin: mockDeviceInfoPlugin,
      );

      expect(
        userAgent,
        '$macOsModel, $macOsKernelVersion, $macOsRelease',
      );
    });

    test('it should be able to get userAgent for Linux platform', () async {
      setUpPlatformInfo(isLinux: true);

      final matomoTracker = await getInitializedMatomoTracker(
        platformInfo: mockPlatformInfo,
      );

      final userAgent = await matomoTracker.getUserAgent(
        deviceInfoPlugin: mockDeviceInfoPlugin,
      );

      expect(
        userAgent,
        linuxPrettyName,
      );
    });
  });
}
