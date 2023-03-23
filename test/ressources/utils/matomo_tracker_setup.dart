import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mock/data.dart';
import '../mock/mock.dart';

void matomoTrackerSetup() {
  TestWidgetsFlutterBinding.ensureInitialized();

  when(mockLocalStorage.getVisitorId).thenAnswer((_) async => null);
  when(() => mockLocalStorage.setVisitorId(any()))
      .thenAnswer((_) => Future.value());
  when(mockLocalStorage.getFirstVisit).thenAnswer((_) async => null);
  when(() => mockLocalStorage.setFirstVisit(any()))
      .thenAnswer((_) => Future.value());
  when(mockLocalStorage.getVisitCount).thenAnswer((_) async => 0);
  when(() => mockLocalStorage.setVisitCount(any()))
      .thenAnswer((_) => Future.value());
  when(mockLocalStorage.getOptOut).thenAnswer((_) async => false);
  when(() => mockLocalStorage.setOptOut(optOut: any(named: 'optOut')))
      .thenAnswer((_) => Future.value());
  when(mockLocalStorage.clear).thenAnswer((_) => Future.value());
  when(() => mockPackageInfo.packageName).thenReturn(matomoTrackerPackageName);
  when(() => mockPackageInfo.packageName).thenReturn(matomoTrackerPackageName);
}
