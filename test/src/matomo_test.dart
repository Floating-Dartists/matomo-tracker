import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/event_info.dart';
import 'package:matomo_tracker/src/matomo.dart';
import 'package:mocktail/mocktail.dart';

import '../ressources/mock/data.dart';
import '../ressources/mock/mock.dart';
import '../ressources/utils/get_initialized_mamoto_tracker.dart';
import '../ressources/utils/matomo_tracker_initialization.dart';
import '../ressources/utils/matomo_tracker_setup.dart';
import '../ressources/utils/matomo_tracker_tracking.dart';
import '../ressources/utils/mock_platform_info.dart';
import '../ressources/utils/uninitialized_test_util.dart';

void main() {
  setUp(matomoTrackerSetup);

  // this test should be the first one to launch, because once the MatomoTracker
  // is initialized, it will not be possible reinitialize it
  test(
    'it should throw ArgumentError if we initialize with wrong visitorId',
    () async {
      await expectLater(
        () => getInitializedMatomoTracker(
          visitorId: matomoTrackerWrongVisitorId,
        ),
        throwsArgumentError,
      );
    },
  );

  group(
    'initialize',
    () {
      // We need to setup matomo tracker mock on each tests because we clear some
      // of the mocks used in the matomo tracker
      setUp(matomoTrackerSetup);

      tearDown(() {
        // We reset shared preferences to avoid side effects between tests
        reset(mockLocalStorage);
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
            mockLocalStorage.getFirstVisit,
          ).thenAnswer((_) async => matomoTrackerLocalFirstVisist);
        },
        [
          (tracker, _) => expect(
                tracker.session.firstVisit,
                matomoTrackerLocalFirstVisist,
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
      await matomoTracker.setOptOut(optOut: true);

      verify(() => mockLocalStorage.setOptOut(optOut: true));
      expect(matomoTracker.optOut, true);
    });

    test('it should be able to get optOut from local db', () async {
      final matomoTracker = await getInitializedMatomoTracker();
      matomoTracker.optOut;

      verify(mockLocalStorage.getOptOut);
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

      verify(mockLocalStorage.clear);
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
          eventName: matomoTrackerEventName,
          eventCategory: matomoTrackerEventCategory,
        );
      },
    );

    testTracking(
      "it should be able to trackScreen and currentScreenId should change of it's given",
      (tracker) {
        when(() => mockBuildContext.widget).thenReturn(matomoTrackerMockWidget);

        tracker.trackScreen(
          mockBuildContext,
          eventName: matomoTrackerEventName,
          eventCategory: matomoTrackerEventCategory,
          pvId: matomoTrackerCurrentScreenId,
        );
      },
      extraExpectations: (tracker) {
        expect(tracker.currentScreenId, matomoTrackerCurrentScreenId);
      },
    );

    group('trackScreenWithName', () {
      uninitializedTest(
        (tracker) {
          final action = matomoTrackerMockWidget.toStringShort();

          tracker.trackScreenWithName(
            actionName: action,
            eventInfo: EventInfo(
              category: matomoEventCategory,
              action: action,
              name: matomoTrackerEventName,
            ),
          );
        },
      );

      testTracking('it should be able to trackScreenWithName', (tracker) {
        tracker.trackScreenWithName(
          actionName: matomoTrackerMockWidget.toStringShort(),
        );
      });

      test(
        'should throw ArgumentError if currentScreenId lenght != 6 ',
        () async {
          final matomoTracker = await getInitializedMatomoTracker();

          await expectLater(
            () => matomoTracker.trackScreenWithName(
              actionName: matomoTrackerMockWidget.toStringShort(),
              pvId: '',
            ),
            throwsArgumentError,
          );
        },
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

  group('setVisitorUserId', () {
    uninitializedTest((tracker) => tracker.setVisitorUserId(uid));

    test('it should be able to set visitor userId', () async {
      final matomoTracker = await getInitializedMatomoTracker();
      matomoTracker.setVisitorUserId(uid);

      expect(matomoTracker.visitor.uid, uid);
    });
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

  group('validateDimension', () {
    final tracker = MatomoTracker();

    test('should not do anything if dimensions is null', () {
      tracker.validateDimension(null);
    });

    test('should not do anything if dimension keys are valid', () {
      const dimensions = <String, String>{
        "dimension1": "value1",
        "dimension2": "value2",
      };

      tracker.validateDimension(dimensions);
    });

    test(
      'should throw an ArgumentError if one of the keys does not start with "dimension"',
      () {
        const dimensions = <String, String>{
          "dimension1": "value1",
          "dim2": "value2",
        };

        expect(
          () => tracker.validateDimension(dimensions),
          throwsArgumentError,
        );
      },
    );

    test(
      'should throw an ArgumentError if one of the keys index is invalid',
      () {
        const dimension = <String, String>{
          "dimension1": "value1",
          "dimension0": "value2",
        };

        expect(
          () => tracker.validateDimension(dimension),
          throwsArgumentError,
        );
      },
    );
  });
}
