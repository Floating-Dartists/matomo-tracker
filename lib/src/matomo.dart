import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:uuid/uuid.dart';

import '../utils/random_alpha_numeric.dart';
import 'matomo_dispatcher.dart';
import 'matomo_event.dart';
import 'session.dart';
import 'tracking_order_item.dart';
import 'visitor.dart';

class MatomoTracker {
  static const kFirstVisit = 'matomo_first_visit';
  static const kVisitCount = 'matomo_visit_count';
  static const kVisitorId = 'matomo_visitor_id';
  static const kOptOut = 'matomo_opt_out';

  final log = Logger('Matomo');

  late MatomoDispatcher _dispatcher;

  static final instance = MatomoTracker._internal();

  MatomoTracker._internal();

  late final int siteId;
  late final String url;
  late final Session session;

  Visitor get visitor => _visitor;
  late Visitor _visitor;

  void setVisitorUserId(String? userId) {
    _visitor =
        Visitor(id: _visitor.id, forcedId: _visitor.forcedId, userId: userId);
  }

  /// The user agent is used to detect the operating system and browser used.
  late final String? userAgent;

  /// URL for the current action.
  late final String contentBase;

  /// The resolution of the device the visitor is using, eg **1280x1024**.
  late final Size screenResolution;

  /// 6 character unique ID that identifies which actions were performed on a
  /// specific page view.
  String? currentScreenId;

  bool initialized = false;
  bool _optout = false;

  SharedPreferences? _prefs;

  final _queue = Queue<MatomoEvent>();
  late Timer _timer;

  String? _tokenAuth;

  String? get getAuthToken => _tokenAuth;

  Future<void> initialize({
    required int siteId,
    required String url,
    String? visitorId,
    String? contentBaseUrl,
    int dequeueInterval = 10,
    String? tokenAuth,
  }) async {
    assert(
      visitorId == null || visitorId.length == 16,
      'visitorId must be 16 characters',
    );
    this.siteId = siteId;
    this.url = url;
    final aVisitorId = visitorId ??
        _prefs?.getString(kVisitorId) ??
        const Uuid().v4().replaceAll('-', '').substring(0, 16);
    _visitor = Visitor(id: aVisitorId, userId: aVisitorId);

    _tokenAuth = tokenAuth;
    _dispatcher = MatomoDispatcher(url, tokenAuth);

    // User agent
    userAgent = await _getUserAgent();

    // Screen Resolution
    screenResolution =
        Size(window.physicalSize.width, window.physicalSize.height);

    // Initialize Session Information
    final now = DateTime.now().toUtc();
    DateTime firstVisit = now;
    int visitCount = 1;

    _prefs = await SharedPreferences.getInstance();

    final localFirstVisit = _prefs?.getInt(kFirstVisit);
    if (localFirstVisit != null) {
      firstVisit = DateTime.fromMillisecondsSinceEpoch(
        localFirstVisit,
        isUtc: true,
      );
    } else {
      unawaited(_prefs?.setInt(kFirstVisit, now.millisecondsSinceEpoch));

      // Save the visitorId for future visits.
      unawaited(_prefs?.setString(kVisitorId, aVisitorId));
    }

    final localVisitorCount = _prefs?.getInt(kVisitCount) ?? 0;
    visitCount += localVisitorCount;
    unawaited(_prefs?.setInt(kVisitCount, visitCount));

    session =
        Session(firstVisit: firstVisit, lastVisit: now, visitCount: visitCount);

    if (contentBaseUrl != null) {
      contentBase = contentBaseUrl;
    } else if (kIsWeb) {
      contentBase = Uri.base.toString();
    } else {
      final packageInfo = await PackageInfo.fromPlatform();
      contentBase = 'https://${packageInfo.packageName}';
    }

    if (_prefs!.containsKey(kOptOut)) {
      _optout = _prefs?.getBool(kOptOut) ?? false;
    } else {
      unawaited(_prefs?.setBool(kOptOut, _optout));
    }

    log.fine(
      'Matomo Initialized: firstVisit=$firstVisit; lastVisit=$now; visitCount=$visitCount; visitorId=$visitorId; contentBase=$contentBase; resolution=${screenResolution.width}x${screenResolution.height}; userAgent=$userAgent',
    );
    initialized = true;

    _timer = Timer.periodic(Duration(seconds: dequeueInterval), (timer) {
      _dequeue();
    });
  }

  Future<String?> _getUserAgent() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (UniversalPlatform.isWeb) {
        final webBrowserInfo = await deviceInfo.webBrowserInfo;

        return webBrowserInfo.userAgent;
      } else if (UniversalPlatform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final release = androidInfo.version.release;
        final sdkInt = androidInfo.version.sdkInt;
        final manufacturer = androidInfo.manufacturer;
        final model = androidInfo.model;

        return 'Android $release (SDK $sdkInt), $manufacturer $model';
      } else if (UniversalPlatform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final systemName = iosInfo.systemName;
        final version = iosInfo.systemVersion;
        final name = iosInfo.name;
        final model = iosInfo.model;

        return '$systemName $version, $name $model';
      } else if (UniversalPlatform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;

        return 'Windows ${windowsInfo.computerName}';
      } else if (UniversalPlatform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        final computerName = macInfo.computerName;
        final model = macInfo.model;
        final version = macInfo.kernelVersion;
        final release = macInfo.osRelease;

        return '$computerName, $model, $version, $release';
      } else if (UniversalPlatform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;

        return linuxInfo.prettyName;
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  bool? get optOut => _optout;

  Future<void> setOptOut({required bool optout}) async {
    _optout = optout;
    await _prefs?.setBool(kOptOut, _optout);
  }

  bool getOptOut() => _prefs?.getBool(kOptOut) ?? false;

  /// Clear the following data from the SharedPreferences:
  ///
  /// - First visit
  /// - Number of visits
  /// - Visitor ID
  void clear() {
    if (_prefs != null) {
      _prefs!.remove(kFirstVisit);
      _prefs!.remove(kVisitCount);
      _prefs!.remove(kVisitorId);
    }
  }

  /// Cancel the timer which checks the queued events to send. (This will not
  /// clear the queue.)
  void dispose() {
    _timer.cancel();
  }

  /// Iterate on the events in the queue and send them to Matomo.
  void dispatchEvents() {
    if (initialized) {
      _dequeue();
    }
  }

  /// This will register an event with [trackScreenWithName] by using the
  /// `context.widget.toStringShort()` value.
  ///
  /// - `eventName`: The name of the event.
  ///
  /// - `currentScreenId`: A 6 character unique ID that identifies which actions
  /// were performed on a specific page view. If `null`, a random id will be
  /// generated.
  ///
  /// - `path`: A string that identifies the path of the screen. If not
  /// `null`, it will be combined to [contentBase] to create a URL.
  void trackScreen(
    BuildContext context, {
    required String eventName,
    String? currentScreenId,
    String? path,
  }) {
    final widgetName = context.widget.toStringShort();
    trackScreenWithName(
      widgetName: widgetName,
      eventName: eventName,
      currentScreenId: currentScreenId,
      path: path,
    );
  }

  /// Register an event with [eventName] as the event's name and [widgetName] as
  /// the event's action.
  ///
  /// - `widgetName`: Equivalent to the event action, here used to identify the
  /// screen with a proper name.
  ///
  /// - `eventName`: The name of the event.
  ///
  /// - `currentScreenId`: A 6 character unique ID that identifies which actions
  /// were performed on a specific page view. If `null`, a random id will be
  /// generated.
  ///
  /// - `path`: A string that identifies the path of the screen. If not
  /// `null`, it will be combined to [contentBase] to create a URL.
  void trackScreenWithName({
    required String widgetName,
    required String eventName,
    String? currentScreenId,
    String? path,
  }) {
    assert(currentScreenId == null || currentScreenId.length == 6);
    this.currentScreenId = currentScreenId ?? randomAlphaNumeric(6);
    return _track(
      MatomoEvent(
        tracker: this,
        eventName: eventName,
        action: widgetName,
        path: path,
      ),
    );
  }

  void trackGoal(int goalId, {double? revenue}) {
    return _track(
      MatomoEvent(
        tracker: this,
        goalId: goalId,
        revenue: revenue,
      ),
    );
  }

  void trackEvent({
    required String eventCategory,
    required String action,
    String? eventName,
    // TODO: Remove when old enough 13.06.2022
    @Deprecated('Please use [eventName] instead') String? name,
    @Deprecated('Please use [eventCategory] instead') String? widgetName,
    int? eventValue,
    Map<String, String>? dimensions,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        action: action,
        eventAction: action,
        eventName: name ?? eventName,
        eventCategory: widgetName ?? eventCategory,
        eventValue: eventValue,
        dimensions: dimensions,
      ),
    );
  }

  void trackDimensions(Map<String, String> dimensions) {
    return _track(
      MatomoEvent(
        tracker: this,
        dimensions: dimensions,
      ),
    );
  }

  void trackSearch({
    required String searchKeyword,
    String? searchCategory,
    int? searchCount,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        searchKeyword: searchKeyword,
        searchCategory: searchCategory,
        searchCount: searchCount,
      ),
    );
  }

  void trackCartUpdate(
    List<TrackingOrderItem>? trackingOrderItems,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount,
  ) {
    return _track(
      MatomoEvent(
        tracker: this,
        goalId: 0,
        trackingOrderItems: trackingOrderItems,
        subTotal: subTotal,
        taxAmount: taxAmount,
        shippingCost: shippingCost,
        discountAmount: discountAmount,
      ),
    );
  }

  void trackOrder(
    String? orderId,
    List<TrackingOrderItem>? trackingOrderItems,
    num? revenue,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount,
  ) {
    return _track(
      MatomoEvent(
        tracker: this,
        goalId: 0,
        orderId: orderId,
        trackingOrderItems: trackingOrderItems,
        revenue: revenue,
        subTotal: subTotal,
        taxAmount: taxAmount,
        shippingCost: shippingCost,
        discountAmount: discountAmount,
      ),
    );
  }

  void trackOutlink(
    String? link,
  ) {
    return _track(
      MatomoEvent(
        tracker: this,
        link: link,
      ),
    );
  }

  void _track(MatomoEvent event) {
    _queue.add(event);
  }

  void _dequeue() {
    assert(initialized);
    log.finest('Processing queue ${_queue.length}');
    while (_queue.isNotEmpty) {
      final event = _queue.removeFirst();
      if (!_optout) {
        _dispatcher.send(event);
      }
    }
  }
}
