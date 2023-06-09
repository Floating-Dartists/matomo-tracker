import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:matomo_tracker/src/dispatch_settings.dart';
import 'package:matomo_tracker/src/local_storage/local_storage.dart';

class PersistentQueue extends DelegatingQueue<Map<String, String>> {
  PersistentQueue._(this._storage, Queue<Map<String, String>> base)
      : _needsSave = false,
        super(base);

  static Future<PersistentQueue> load({
    required LocalStorage storage,
    required PersistenceFilter onLoadFilter,
  }) async {
    final actionsData = await storage.loadActions();
    final actions = decode(actionsData)..retainWhere(onLoadFilter);
    final queue = PersistentQueue._(storage, Queue.of(actions));
    await queue.save();
    return queue;
  }

  @visibleForTesting
  static List<Map<String, String>> decode(String? actionsData) {
    if (actionsData != null) {
      final actions = jsonDecode(actionsData);
      if (actions is! List) {
        throw FormatException('Expected a list of actions, but got: $actions');
      }
      return actions
          .cast<Map<String, dynamic>>()
          .map<Map<String, String>>((element) => element.cast())
          .toList();
    } else {
      return [];
    }
  }

  final LocalStorage _storage;
  bool _needsSave;
  Completer<void>? _saveInProgress;
  @visibleForTesting
  bool get saveInProgress => _saveInProgress != null;

  @visibleForTesting
  Future<void> save() {
    _needsSave = true;
    final effectiveSaveInProgress = _saveInProgress ?? Completer<void>();
    if (effectiveSaveInProgress != _saveInProgress) {
      assert(_saveInProgress == null);
      _saveInProgress = effectiveSaveInProgress;
      unawaited(
        Future(() async {
          try {
            while (_needsSave) {
              _needsSave = false;
              final data = json.encode(toList());
              await _storage.storeActions(data);
            }
            effectiveSaveInProgress.complete();
          } catch (error, stackTrace) {
            effectiveSaveInProgress.completeError(error, stackTrace);
          } finally {
            _saveInProgress = null;
          }
        }),
      );
    }
    return effectiveSaveInProgress.future;
  }

  void _unawaitedSave() => unawaited(save());

  @override
  void add(Map<String, String> value) {
    super.add(value);
    _unawaitedSave();
  }

  @override
  void addAll(Iterable<Map<String, String>> iterable) {
    super.addAll(iterable);
    _unawaitedSave();
  }

  @override
  void addFirst(Map<String, String> value) {
    super.addFirst(value);
    _unawaitedSave();
  }

  @override
  void addLast(Map<String, String> value) {
    super.addLast(value);
    _unawaitedSave();
  }

  @override
  void clear() {
    super.clear();
    _unawaitedSave();
  }

  @override
  bool remove(Object? object) {
    final result = super.remove(object);
    _unawaitedSave();
    return result;
  }

  @override
  Map<String, String> removeFirst() {
    final result = super.removeFirst();
    _unawaitedSave();
    return result;
  }

  @override
  Map<String, String> removeLast() {
    final result = super.removeLast();
    _unawaitedSave();
    return result;
  }

  @override
  void removeWhere(bool Function(Map<String, String> element) test) {
    super.removeWhere(test);
    _unawaitedSave();
  }

  @override
  void retainWhere(bool Function(Map<String, String> element) test) {
    super.retainWhere(test);
    _unawaitedSave();
  }
}
