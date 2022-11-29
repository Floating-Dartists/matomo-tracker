import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../utils/lock.dart' as sync;
import '../utils/random_alpha_numeric.dart';
import 'logger.dart';
import 'matomo_dispatcher.dart';
import 'matomo_event.dart';
import 'platform_info/platform_info.dart';
import 'session.dart';
import 'tracking_order_item.dart';
import 'visitor.dart';

class MatomoTracker {
  static const kFirstVisit = 'matomo_first_visit';
  static const kVisitCount = 'matomo_visit_count';
  static const kVisitorId = 'matomo_visitor_id';
  static const kOptOut = 'matomo_opt_out';

  final log = Logger('Matomo');
  final _platformInfo = PlatformInfo.instance;

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

  @visibleForTesting
  final queue = Queue<MatomoEvent>();

  @visibleForTesting
  late Timer timer;

  late sync.Lock _lock;

  String? _tokenAuth;

  String? get getAuthToken => _tokenAuth;

  late int _dequeueInterval;

  Future<void> initialize({
    required int siteId,
    required String url,
    String? visitorId,
    String? contentBaseUrl,
    int dequeueInterval = 10,
    String? tokenAuth,
    SharedPreferences? prefs,
    PackageInfo? packageInfo,
  }) async {
    assert(
      visitorId == null || visitorId.length == 16,
      'visitorId must be 16 characters',
    );
    this.siteId = siteId;
    this.url = url;
    _dequeueInterval = dequeueInterval;
    _lock = sync.Lock();
    _prefs = prefs ?? await SharedPreferences.getInstance();

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
    final now = clock.now().toUtc();
    DateTime firstVisit = now;
    int visitCount = 1;

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
      final effectivePackageInfo =
          packageInfo ?? await PackageInfo.fromPlatform();
      contentBase = 'https://${effectivePackageInfo.packageName}';
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

    timer = Timer.periodic(Duration(seconds: _dequeueInterval), (timer) {
      _dequeue();
    });
  }

  Future<String?> _getUserAgent() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (_platformInfo.isWeb) {
        final webBrowserInfo = await deviceInfo.webBrowserInfo;

        return webBrowserInfo.userAgent;
      } else if (_platformInfo.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final release = androidInfo.version.release;
        final sdkInt = androidInfo.version.sdkInt;
        final manufacturer = androidInfo.manufacturer;
        final model = androidInfo.model;

        return 'Android $release (SDK $sdkInt), $manufacturer $model';
      } else if (_platformInfo.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final systemName = iosInfo.systemName;
        final version = iosInfo.systemVersion;
        final model = iosInfo.model;

        return '$systemName $version, $model';
      } else if (_platformInfo.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        final releaseId = windowsInfo.releaseId;
        final buildNumber = windowsInfo.buildNumber;

        return 'Windows $releaseId.$buildNumber';
      } else if (_platformInfo.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        final model = macInfo.model;
        final version = macInfo.kernelVersion;
        final release = macInfo.osRelease;

        return '$model, $version, $release';
      } else if (_platformInfo.isLinux) {
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
    timer.cancel();
  }

  // Pause tracker
  void pause() {
    if (initialized) {
      timer.cancel();
      _dequeue();
    }
  }

  // Resume tracker
  void resume() {
    if (initialized && !timer.isActive) {
      timer = Timer.periodic(Duration(seconds: _dequeueInterval), (timer) {
        _dequeue();
      });
    }
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
    Map<String, String>? dimensions,
  }) {
    if (currentScreenId != null) {
      this.currentScreenId = currentScreenId;
    }
    final widgetName = context.widget.toStringShort();
    trackScreenWithName(
      widgetName: widgetName,
      eventName: eventName,
      currentScreenId: currentScreenId,
      path: path,
      dimensions: dimensions,
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
    Map<String, String>? dimensions,
  }) {
    assert(currentScreenId == null || currentScreenId.length == 6);
    this.currentScreenId = currentScreenId ?? randomAlphaNumeric(6);
    return _track(
      MatomoEvent(
        tracker: this,
        eventName: eventName,
        action: widgetName,
        path: path,
        dimensions: dimensions,
      ),
    );
  }

  void trackGoal(
    int goalId, {
    double? revenue,
    Map<String, String>? dimensions,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        goalId: goalId,
        revenue: revenue,
        dimensions: dimensions,
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
    Map<String, String>? dimensions,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        searchKeyword: searchKeyword,
        searchCategory: searchCategory,
        searchCount: searchCount,
        dimensions: dimensions,
      ),
    );
  }

  void trackCartUpdate(
    List<TrackingOrderItem>? trackingOrderItems,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount, {
    Map<String, String>? dimensions,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        goalId: 0,
        trackingOrderItems: trackingOrderItems,
        subTotal: subTotal,
        taxAmount: taxAmount,
        shippingCost: shippingCost,
        discountAmount: discountAmount,
        dimensions: dimensions,
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
    num? discountAmount, {
    Map<String, String>? dimensions,
  }) {
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
        dimensions: dimensions,
      ),
    );
  }

  void trackOutlink(
    String? link, {
    Map<String, String>? dimensions,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        link: link,
        dimensions: dimensions,
      ),
    );
  }

  void _track(MatomoEvent event) {
    queue.add(event);
  }

  void _dequeue() {
    assert(initialized);
    log.finest('Processing queue ${queue.length}');
    if (!_lock.locked) {
      _lock.synchronized(() {
        final events = List<MatomoEvent>.from(queue);
        queue.clear();
        if (!_optout) {
          _dispatcher.sendBatch(events);
        }
      });
    }
  }
}
