import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/dispatch_settings.dart';
import 'package:matomo_tracker/src/matomo_action.dart';
import 'package:mocktail/mocktail.dart';
import '../ressources/mock/data.dart';
import '../ressources/mock/mock.dart';

const _uid1 = 'user1';
const _uid2 = 'user2';

const _deepCollectionEquality = DeepCollectionEquality();
bool deepEquals(Object? a, Object? b) => _deepCollectionEquality.equals(a, b);

void main() {
  group('DispatchSettings', () {
    test('it should be able to create non-persistent DispatchSettings', () {
      const settings = DispatchSettings.nonPersistent();
      expect(settings.persistentQueue, false);
      expect(settings.onLoad, isNull);
    });

    test('it should be able to create persistent DispatchSettings', () {
      const settings = DispatchSettings.persistent();
      expect(settings.persistentQueue, true);
      expect(settings.onLoad, isNotNull);
    });
  });

  group('PersistenceFilter', () {
    setUpAll(() {
      when(() => mockMatomoTracker.visitor).thenReturn(mockVisitor);
      when(() => mockMatomoTracker.session).thenReturn(mockSession);
      when(() => mockMatomoTracker.screenResolution)
          .thenReturn(matomoTrackerScreenResolution);
      when(() => mockMatomoTracker.contentBase)
          .thenReturn(matomoTrackerContentBase);
      when(() => mockMatomoTracker.siteId).thenReturn(matomoTrackerSiteId);
      when(() => mockVisitor.id).thenReturn(visitorId);
      when(() => mockVisitor.uid).thenReturn(uid);
      when(mockTrackingOrderItem.toArray).thenReturn([]);
      when(() => mockSession.visitCount).thenReturn(sessionVisitCount);
      when(() => mockSession.lastVisit).thenReturn(sessionLastVisite);
      when(() => mockSession.firstVisit).thenReturn(sessionFirstVisite);
    });

    Map<String, String> recentUser1(DateTime now) =>
        withClock(Clock.fixed(now.add(const Duration(hours: -5))), () {
          when(() => mockVisitor.uid).thenReturn(_uid1);
          return MatomoAction().toMap(mockMatomoTracker)..remove('rand');
        });

    Map<String, String> oldUser2(DateTime now) =>
        withClock(Clock.fixed(now.add(const Duration(hours: -5, days: -1))),
            () {
          when(() => mockVisitor.uid).thenReturn(_uid2);
          return MatomoAction().toMap(mockMatomoTracker)..remove('rand');
        });

    List<Map<String, String>> getStoredActions(DateTime now) =>
        [oldUser2(now), recentUser1(now)];

    test('takeAll should not change the action list', () {
      final now = DateTime.now();
      final before = getStoredActions(now);
      final after = getStoredActions(now)
        ..retainWhere(DispatchSettings.takeAll);
      expect(deepEquals(before, after), isTrue);
    });

    test('dropAll should produce an empty action list', () {
      final actions = getStoredActions(DateTime.now())
        ..retainWhere(DispatchSettings.dropAll);
      expect(actions, isEmpty);
    });

    test('whereNotOlderThanADay should only retain the recent action', () {
      final now = DateTime.now();
      final recent = recentUser1(now);
      final after = getStoredActions(now)
        ..retainWhere(DispatchSettings.whereNotOlderThanADay);
      expect(deepEquals([recent], after), isTrue);
    });

    test(
        'whereNotOlderThan should only retain some actions based on the duration',
        () {
      final now = DateTime.now();
      final recent = recentUser1(now);
      final old = oldUser2(now);
      final unchanged = getStoredActions(now)
        ..retainWhere(
          DispatchSettings.whereNotOlderThan(const Duration(days: 2)),
        );
      final onlyRecent = getStoredActions(now)
        ..retainWhere(
          DispatchSettings.whereNotOlderThan(const Duration(days: 1)),
        );
      final none = getStoredActions(now)
        ..retainWhere(
          DispatchSettings.whereNotOlderThan(Duration.zero),
        );
      expect(deepEquals([old, recent], unchanged), isTrue);
      expect(deepEquals([recent], onlyRecent), isTrue);
      expect(none, isEmpty);
    });

    test('whereUserId should only retain actions of the specific user', () {
      final now = DateTime.now();
      final uid1 = recentUser1(now);
      final afterUid1 = getStoredActions(now)
        ..retainWhere(DispatchSettings.whereUserId(_uid1));
      final uid2 = oldUser2(now);
      final afterUid2 = getStoredActions(now)
        ..retainWhere(DispatchSettings.whereUserId(_uid2));
      expect(deepEquals([uid1], afterUid1), isTrue);
      expect(deepEquals([uid2], afterUid2), isTrue);
    });

    test('chain should chain filters together', () {
      final now = DateTime.now();
      final recent = recentUser1(now);
      final old = oldUser2(now);
      final chained = DispatchSettings.chain(
        [
          // will filter out recent
          DispatchSettings.whereUserId(_uid2),
          // will filter out old
          DispatchSettings.whereNotOlderThanADay,
        ],
      );
      final after = [old, recent]..retainWhere(chained);
      expect(after, isEmpty);
    });

    test(
        'chaining only one filter should result in the same result as the filter',
        () {
      final now = DateTime.now();
      final chained = DispatchSettings.chain(
        [DispatchSettings.whereNotOlderThanADay],
      );
      final withChained = getStoredActions(now)..retainWhere(chained);
      final withoutChain = getStoredActions(now)
        ..retainWhere(DispatchSettings.whereNotOlderThanADay);
      expect(
        deepEquals(
          withChained,
          withoutChain,
        ),
        isTrue,
      );
    });

    test('chain should stop eagerly', () {
      final now = DateTime.now();
      bool alwaysThrows(Map<String, String> action) =>
          throw StateError('Unreachable');
      final produceEmpty = DispatchSettings.chain(
        [DispatchSettings.dropAll, alwaysThrows],
      );
      final produceError = DispatchSettings.chain(
        [DispatchSettings.takeAll, alwaysThrows],
      );
      final empty = getStoredActions(now)..retainWhere(produceEmpty);
      expect(empty, isEmpty);
      expect(
        () => getStoredActions(now).retainWhere(produceError),
        throwsStateError,
      );
    });
  });
}
