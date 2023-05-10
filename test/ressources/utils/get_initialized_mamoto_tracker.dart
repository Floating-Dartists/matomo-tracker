import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:matomo_tracker/src/platform_info/platform_info.dart';

import '../mock/data.dart';
import '../mock/mock.dart';

/// Used to get a [MatomoTracker] instance.
/// By default, it will return a new instance of [MatomoTracker]
/// This is used to ensure that the tests are independent of each other.
///
/// for some reason if there is weird behaviors, you can pass by the `instance`
/// static variable. You just have to pass `shouldForceCreation: false`.
Future<MatomoTracker> getInitializedMatomoTracker({
  String? visitorId,
  String? uid,
  String? contentBaseUrl,
  String? tokenAuth,
  PlatformInfo? platformInfo,
  bool shouldForceCreation = true,
}) async {
  final matomoTracker =
      shouldForceCreation ? MatomoTracker() : MatomoTracker.instance;
  if (matomoTracker.initialized) {
    return matomoTracker;
  }

  await matomoTracker.initialize(
    url: matomoTrackerUrl,
    siteId: matomoTrackerSiteId,
    localStorage: mockLocalStorage,
    packageInfo: mockPackageInfo,
    visitorId: visitorId,
    uid: uid,
    contentBaseUrl: contentBaseUrl,
    tokenAuth: tokenAuth,
    platformInfo: platformInfo,
  );

  return matomoTracker;
}
