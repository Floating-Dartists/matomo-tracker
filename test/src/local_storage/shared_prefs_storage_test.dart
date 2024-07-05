import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/local_storage/shared_prefs_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ressources/mock/data.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('SharedPrefsStorage', () {
    late MockSharedPreferences mockPrefs;
    late SharedPrefsStorage sharedPrefsStorage;

    setUpAll(() {
      mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getInt(any())).thenReturn(null);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

      sharedPrefsStorage = SharedPrefsStorage()..prefs = mockPrefs;
    });

    test('getVisitorId should call getString on kVisitorId', () async {
      await sharedPrefsStorage.getVisitorId();
      verify(() => mockPrefs.getString(SharedPrefsStorage.kVisitorId));
    });

    test('setVisitorId should call setString', () async {
      await sharedPrefsStorage.setVisitorId(matomoTrackerVisitorId);
      verify(
        () => mockPrefs.setString(
          SharedPrefsStorage.kVisitorId,
          matomoTrackerVisitorId,
        ),
      );
    });

    test('getOptOut should call getBool', () async {
      await sharedPrefsStorage.getOptOut();
      verify(() => mockPrefs.getBool(SharedPrefsStorage.kOptOut));
    });

    test('setOptOut should call setBool', () async {
      await sharedPrefsStorage.setOptOut(optOut: true);
      verify(() => mockPrefs.setBool(SharedPrefsStorage.kOptOut, true));
    });

    test(
      'clear should call remove on kVisitorId and kPersistentQueue',
      () async {
        await sharedPrefsStorage.clear();
        verify(() => mockPrefs.remove(SharedPrefsStorage.kVisitorId));
        verify(() => mockPrefs.remove(SharedPrefsStorage.kPersistentQueue));
      },
    );

    test('loadActions should call getString on kPersistentQueue', () async {
      await sharedPrefsStorage.loadActions();
      verify(() => mockPrefs.getString(SharedPrefsStorage.kPersistentQueue));
    });

    test('storeActions should call setString', () async {
      await sharedPrefsStorage.storeActions(matomoTrackerVisitorId);
      verify(
        () => mockPrefs.setString(
          SharedPrefsStorage.kPersistentQueue,
          matomoTrackerVisitorId,
        ),
      );
    });
  });
}
