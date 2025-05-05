import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mock/data.dart';
import '../mock/mock.dart';

void matomoTrackerSetup({String? visitorId}) {
  TestWidgetsFlutterBinding.ensureInitialized();

  when(mockLocalStorage.getVisitorId).thenAnswer((_) async => visitorId);
  when(() => mockLocalStorage.setVisitorId(any()))
      .thenAnswer((_) => Future.value());
  when(mockLocalStorage.getOptOut).thenAnswer((_) async => false);
  when(() => mockLocalStorage.setOptOut(optOut: any(named: 'optOut')))
      .thenAnswer((_) => Future.value());
  when(mockLocalStorage.clear).thenAnswer((_) => Future.value());
  when(() => mockPackageInfo.packageName).thenReturn(matomoTrackerPackageName);
}
