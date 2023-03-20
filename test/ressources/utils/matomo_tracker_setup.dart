import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mock/data.dart';
import '../mock/mock.dart';

void matomoTrackerSetup() {
  TestWidgetsFlutterBinding.ensureInitialized();

  when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
  when(() => mockSharedPreferences.getString(any())).thenReturn(null);
  when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
  when(() => mockSharedPreferences.containsKey(any())).thenReturn(false);
  when(() => mockSharedPreferences.setInt(any(), any()))
      .thenAnswer((_) async => true);
  when(() => mockSharedPreferences.setString(any(), any()))
      .thenAnswer((_) async => true);
  when(() => mockSharedPreferences.setBool(any(), any()))
      .thenAnswer((_) async => true);
  when(() => mockSharedPreferences.remove(any())).thenAnswer((_) async => true);
  when(() => mockPackageInfo.packageName).thenReturn(matomoTrackerPackageName);
  when(() => mockPackageInfo.packageName).thenReturn(matomoTrackerPackageName);
}
