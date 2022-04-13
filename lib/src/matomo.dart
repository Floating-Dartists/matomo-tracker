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
  late final Visitor visitor;
  late final String? userAgent;
  late final String contentBase;
  late final int width;
  late final int height;
  String? currentScreenId;

  bool initialized = false;
  bool _optout = false;

  SharedPreferences? _prefs;

  final _queue = Queue<MatomoEvent>();
  late Timer _timer;

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
    final _visitorId = visitorId ??
        _prefs?.getString(kVisitorId) ??
        const Uuid().v4().replaceAll('-', '').substring(0, 16);
    visitor = Visitor(id: _visitorId, userId: _visitorId);

    _dispatcher = MatomoDispatcher(url, tokenAuth);

    // User agent
    userAgent = await _getUserAgent();

    // Screen Resolution
    width = window.physicalSize.width.toInt();
    height = window.physicalSize.height.toInt();

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
      unawaited(_prefs?.setString(kVisitorId, _visitorId));
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
      'Matomo Initialized: firstVisit=$firstVisit; lastVisit=$now; visitCount=$visitCount; visitorId=$visitorId; contentBase=$contentBase; resolution=${width}x$height; userAgent=$userAgent',
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

  void setOptOut({required bool optout}) {
    _optout = optout;
    _prefs?.setBool(kOptOut, _optout);
  }

  void clear() {
    if (_prefs != null) {
      _prefs!.remove(kFirstVisit);
      _prefs!.remove(kVisitCount);
      _prefs!.remove(kVisitorId);
    }
  }

  void dispose() {
    _timer.cancel();
  }

  void dispatchEvents() {
    if (initialized) {
      _dequeue();
    }
  }

  /// This will register an event with [trackScreenWithName] by using the
  /// `context.widget.toStringShort()` value.
  void trackScreen(
    BuildContext context, {
    required String eventName,
    String? currentScreenId,
  }) {
    final widgetName = context.widget.toStringShort();
    trackScreenWithName(
      widgetName: widgetName,
      eventName: eventName,
      currentScreenId: currentScreenId,
    );
  }

  /// Register an event with [eventName] as the event's name and [widgetName] as
  /// the event's action.
  ///
  /// If [currentScreenId] is null a random id will be generated.
  void trackScreenWithName({
    required String widgetName,
    required String eventName,
    String? currentScreenId,
  }) {
    this.currentScreenId = currentScreenId ?? randomAlphaNumeric(6);
    return _track(
      MatomoEvent(
        tracker: this,
        eventName: eventName,
        action: widgetName,
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
    required String name,
    required String action,
    String? widgetName,
    int? eventValue,
  }) {
    return _track(
      MatomoEvent(
        tracker: this,
        eventAction: action,
        eventName: name,
        eventCategory: widgetName,
        eventValue: eventValue,
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

class Session {
  final DateTime firstVisit;
  final DateTime lastVisit;
  final int visitCount;

  Session({
    required this.firstVisit,
    required this.lastVisit,
    required this.visitCount,
  });
}

class Visitor {
  final String? id;
  final String? forcedId;
  final String? userId;

  Visitor({
    this.id,
    this.forcedId,
    this.userId,
  });
}

class TrackingOrderItem {
  final String? sku;
  final String? name;
  final String? category;
  final num? price;
  final int? quantity;

  TrackingOrderItem({
    this.sku,
    this.name,
    this.category,
    this.price,
    this.quantity,
  });

  List<Object?> toArray() => [sku, name, category, price, quantity];
}
