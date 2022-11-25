import 'package:matomo_tracker/matomo_tracker.dart';

import '../mock/data.dart';
import '../mock/mock.dart';

Future<MatomoTracker> getInitializedMatomoTracker({String? visitorId}) async {
  final matomoTracker = MatomoTracker.instance;
  if (matomoTracker.initialized) {
    return matomoTracker;
  }

  await matomoTracker.initialize(
    url: matomoTrackerUrl,
    siteId: matomoTrackerSiteId,
    prefs: mockSharedPreferences,
    packageInfo: mockPackageInfo,
    visitorId: visitorId,
  );

  return matomoTracker;
}
