import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:matomo_tracker/src/local_storage/shared_prefs_storage.dart';
import 'package:matomo_tracker/src/persistent_queue.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dispatch_settings_test.dart';
import 'local_storage/shared_prefs_storage_test.dart';

typedef QueueCall<T> = T Function(Queue<Map<String, String>> queue);
typedef AdditionalExpect = void Function(
  PersistentQueue original,
  PersistentQueue restored,
  Queue<Map<String, String>> reference,
);

bool _action1Filter(Map<String, String> action) =>
    action['action1'] == 'value1';
const _nonEmptyJson = '[{"action1":"value1"},{"action2":"value2"}]';
const _nonEmptyJsonElementCount = 2;
const _action = <String, String>{'action3': 'value3'};
const _actions = [
  _action,
  <String, String>{'action4': 'value4'},
];

void main() {
  group('decode', () {
    test('it should be able to decode an empty list', () {
      final decoded = PersistentQueue.decode('[]');
      expect(decoded, isEmpty);
    });

    test('decoding null should result in an empty list', () {
      final decoded = PersistentQueue.decode(null);
      expect(decoded, isEmpty);
    });

    test('it should be able to decode a stored list', () {
      final decoded = PersistentQueue.decode(_nonEmptyJson);
      expect(decoded.length, _nonEmptyJsonElementCount);
    });
  });

  group('load', () {
    test('load should apply the onLoad PersistenceFilter', () async {
      SharedPreferences.setMockInitialValues(
        {SharedPrefsStorage.kPersistentQueue: _nonEmptyJson},
      );
      final sharedPrefsStorage = SharedPrefsStorage();
      final takeAllQueue = await PersistentQueue.load(
        storage: sharedPrefsStorage,
        onLoadFilter: DispatchSettings.takeAll,
      );
      expect(takeAllQueue.length, _nonEmptyJsonElementCount);
      final dropAllQueue = await PersistentQueue.load(
        storage: sharedPrefsStorage,
        onLoadFilter: DispatchSettings.dropAll,
      );
      expect(dropAllQueue, isEmpty);
    });

    test('load should create an empty queue if no data was stored', () async {
      SharedPreferences.setMockInitialValues({});
      final sharedPrefsStorage = SharedPrefsStorage();
      final persistentQueue = await PersistentQueue.load(
        storage: sharedPrefsStorage,
        onLoadFilter: DispatchSettings.takeAll,
      );
      expect(persistentQueue, isEmpty);
    });

    test('if data were stored, load should recreate a deep equal queue',
        () async {
      SharedPreferences.setMockInitialValues(
        {SharedPrefsStorage.kPersistentQueue: _nonEmptyJson},
      );
      final sharedPrefsStorage = SharedPrefsStorage();
      final persistentQueue = await PersistentQueue.load(
        storage: sharedPrefsStorage,
        onLoadFilter: DispatchSettings.takeAll,
      );
      expect(persistentQueue.length, _nonEmptyJsonElementCount);
      expect(
        deepEquals(
          json.decode(_nonEmptyJson),
          persistentQueue.toList(),
        ),
        isTrue,
      );
    });
  });

  group('save', () {
    late SharedPrefsStorage sharedPrefsStorage;
    setUp(() {
      SharedPreferences.setMockInitialValues(
        {SharedPrefsStorage.kPersistentQueue: _nonEmptyJson},
      );
      sharedPrefsStorage = SharedPrefsStorage();
    });

    Future<PersistentQueue> load() => PersistentQueue.load(
          storage: sharedPrefsStorage,
          onLoadFilter: DispatchSettings.takeAll,
        );

    test(
      'multiple unawaited invokations of save should result in a identical future',
      () async {
        final persistentQueue = await load();
        var last = persistentQueue.save();
        expect(persistentQueue.saveInProgress, isTrue);
        for (int i = 0; i < 10; i++) {
          final next = persistentQueue.save();
          expect(identical(last, next), isTrue);
          last = next;
        }
        await last;
        expect(persistentQueue.saveInProgress, isFalse);
      },
    );

    test(
      'multiple awaited invokations of save should result in different futures',
      () async {
        final persistentQueue = await load();
        var last = persistentQueue.save();
        expect(persistentQueue.saveInProgress, isTrue);
        for (int i = 0; i < 10; i++) {
          await last;
          final next = persistentQueue.save();
          expect(identical(last, next), isFalse);
          last = next;
        }
        await last;
        expect(persistentQueue.saveInProgress, isFalse);
      },
    );

    test('save should write data to the local storage', () async {
      final mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      final sharedPrefsStorage = SharedPrefsStorage()..prefs = mockPrefs;
      final persistentQueue = await PersistentQueue.load(
        storage: sharedPrefsStorage,
        onLoadFilter: DispatchSettings.takeAll,
      );
      await persistentQueue.save();
      verify(
        () => mockPrefs.setString(
          SharedPrefsStorage.kPersistentQueue,
          any(),
        ),
      );
    });

    test(
      'after concurrent calls to save, the saved data should reflect the last instance',
      () async {
        final persistentQueue = await load();
        persistentQueue.clear();
        unawaited(persistentQueue.save());
        persistentQueue.addAll(_actions);
        unawaited(persistentQueue.save());
        persistentQueue.removeLast();
        await persistentQueue.save();
        expect(persistentQueue.length, 1);
        expect(persistentQueue.first, _action);
        final reconstructed = await load();
        expect(deepEquals(persistentQueue, reconstructed), isTrue);
      },
    );
  });

  group('modify', () {
    late SharedPrefsStorage sharedPrefsStorage;
    setUp(() {
      SharedPreferences.setMockInitialValues(
        {SharedPrefsStorage.kPersistentQueue: _nonEmptyJson},
      );
      sharedPrefsStorage = SharedPrefsStorage();
    });

    Future<PersistentQueue> load() => PersistentQueue.load(
          storage: sharedPrefsStorage,
          onLoadFilter: DispatchSettings.takeAll,
        );

    // Idea is to use this as generic test by applying the call on a
    // PersistentQueue and a reference Queue and compare them for equality
    void testCall<T>(
      String description,
      QueueCall<T> call, [
      AdditionalExpect? additionalExpect,
    ]) {
      test(description, () async {
        final persistentQueue = await load();
        expect(persistentQueue.length, _nonEmptyJsonElementCount);
        final reference = Queue.of(persistentQueue);
        expect(deepEquals(persistentQueue, reference), isTrue);
        final callResult = call(persistentQueue);
        final referenceResult = call(reference);
        expect(callResult, referenceResult);
        expect(deepEquals(persistentQueue, reference), isTrue);
        expect(persistentQueue.saveInProgress, isTrue);
        await persistentQueue.save();
        expect(persistentQueue.saveInProgress, isFalse);
        final reconstructed = await load();
        expect(deepEquals(reconstructed, reference), isTrue);
        expect(deepEquals(reconstructed, persistentQueue), isTrue);
        if (additionalExpect != null) {
          additionalExpect(persistentQueue, reconstructed, reference);
        }
      });
    }

    testCall(
      'add should modify the queue and call save',
      (queue) => queue.add(_action),
      (a, b, c) => expect(b.length, _nonEmptyJsonElementCount + 1),
    );

    testCall(
      'addAll should modify the queue and call save',
      (queue) => queue.addAll(_actions),
      (a, b, c) =>
          expect(b.length, _nonEmptyJsonElementCount + _actions.length),
    );

    testCall(
      'addFirst should modify the queue and call save',
      (queue) => queue.addFirst(_action),
      (a, b, c) => expect(mapEquals(b.first, _action), isTrue),
    );

    testCall(
      'addLast should modify the queue and call save',
      (queue) => queue.addLast(_action),
      (a, b, c) => expect(mapEquals(b.last, _action), isTrue),
    );

    testCall(
      'clear should modify the queue and call save',
      (queue) => queue.clear(),
      (a, b, c) => expect(b, isEmpty),
    );

    testCall('remove should modify the queue and call save', (queue) {
      queue.add(_action);
      expect(queue.length, _nonEmptyJsonElementCount + 1);
      queue.remove(_action);
      expect(queue.length, _nonEmptyJsonElementCount);
    });

    testCall(
      'remove should not modify the queue but call save if the element is not in the list',
      (queue) => queue.remove({'not': 'there'}),
      (a, b, c) => expect(b.length, _nonEmptyJsonElementCount),
    );

    testCall(
      'removeFirst should modify the queue and call save',
      (queue) => queue.removeFirst(),
      (a, b, c) => expect(b.first['action2'], 'value2'),
    );

    testCall(
      'removeLast should modify the queue and call save',
      (queue) => queue.removeLast(),
      (a, b, c) => expect(b.last['action1'], 'value1'),
    );

    testCall(
      'removeWhere should modify the queue and call save',
      (queue) => queue.removeWhere(_action1Filter),
      (a, b, c) => expect(b.first['action2'], 'value2'),
    );

    testCall(
      'retainWhere should modify the queue and call save',
      (queue) => queue.retainWhere(_action1Filter),
      (a, b, c) => expect(b.last['action1'], 'value1'),
    );
  });
}
