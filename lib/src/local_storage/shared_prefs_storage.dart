import 'package:flutter/material.dart';
import 'package:matomo_tracker/src/local_storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsStorage implements LocalStorage {
  static const kVisitorId = 'matomo_visitor_id';
  static const kOptOut = 'matomo_opt_out';
  static const kPersistentQueue = 'matomo_persistent_queue';

  SharedPreferences? _prefs;

  @visibleForTesting
  set prefs(SharedPreferences prefs) => _prefs = prefs;

  Future<SharedPreferences> _getSharedPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> getVisitorId() async {
    final prefs = await _getSharedPrefs();
    return prefs.getString(kVisitorId);
  }

  @override
  Future<void> setVisitorId(String visitorId) async {
    final prefs = await _getSharedPrefs();
    await prefs.setString(kVisitorId, visitorId);
  }

  @override
  Future<bool> getOptOut() async {
    final prefs = await _getSharedPrefs();
    return prefs.getBool(kOptOut) ?? false;
  }

  @override
  Future<void> setOptOut({required bool optOut}) async {
    final prefs = await _getSharedPrefs();
    await prefs.setBool(kOptOut, optOut);
  }

  @override
  Future<void> clear() async {
    final prefs = await _getSharedPrefs();
    await Future.wait([
      prefs.remove(kVisitorId),
      prefs.remove(kPersistentQueue),
    ]);
  }

  @override
  Future<String?> loadActions() async {
    final prefs = await _getSharedPrefs();
    return prefs.getString(kPersistentQueue);
  }

  @override
  Future<void> storeActions(String serializedActions) async {
    final prefs = await _getSharedPrefs();
    await prefs.setString(kPersistentQueue, serializedActions);
  }
}
