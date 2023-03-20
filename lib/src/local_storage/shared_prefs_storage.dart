import 'package:flutter/material.dart';
import 'package:matomo_tracker/src/local_storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsStorage implements LocalStorage {
  static const kFirstVisit = 'matomo_first_visit';
  static const kVisitCount = 'matomo_visit_count';
  static const kVisitorId = 'matomo_visitor_id';
  static const kOptOut = 'matomo_opt_out';

  SharedPreferences? _prefs;

  @visibleForTesting
  set prefs(SharedPreferences prefs) => _prefs = prefs;

  Future<SharedPreferences> _getSharedPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<DateTime?> getFirstVisit() async {
    final prefs = await _getSharedPrefs();
    final firstVisit = prefs.getInt(kFirstVisit);

    if (firstVisit == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(firstVisit, isUtc: true);
  }

  @override
  Future<String?> getVisitorId() async {
    final prefs = await _getSharedPrefs();
    return prefs.getString(kVisitorId);
  }

  @override
  Future<void> setFirstVisit(DateTime firstVisit) async {
    final prefs = await _getSharedPrefs();
    await prefs.setInt(kFirstVisit, firstVisit.millisecondsSinceEpoch);
  }

  @override
  Future<void> setVisitorId(String visitorId) async {
    final prefs = await _getSharedPrefs();
    await prefs.setString(kVisitorId, visitorId);
  }

  @override
  Future<int> getVisitCount() async {
    final prefs = await _getSharedPrefs();
    return prefs.getInt(kVisitCount) ?? 0;
  }

  @override
  Future<void> setVisitCount(int visitCount) async {
    final prefs = await _getSharedPrefs();
    await prefs.setInt(kVisitCount, visitCount);
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
      prefs.remove(kFirstVisit),
      prefs.remove(kVisitCount),
      prefs.remove(kVisitorId),
    ]);
  }
}
