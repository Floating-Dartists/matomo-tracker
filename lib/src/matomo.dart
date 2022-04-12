import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:matomo/src/random_alpha_numeric.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:uuid/uuid.dart';

abstract class TraceableStatelessWidget extends StatelessWidget {
  final String name;
  final String title;

  const TraceableStatelessWidget({
    this.name = '',
    this.title = 'WidgetCreated',
    Key? key,
  }) : super(key: key);

  @override
  StatelessElement createElement() {
    MatomoTracker.trackScreenWithName(
      name.isEmpty ? runtimeType.toString() : name,
      title,
    );
    return StatelessElement(this);
  }
}

abstract class TraceableStatefulWidget extends StatefulWidget {
  final String name;
  final String title;

  const TraceableStatefulWidget({
    this.name = '',
    this.title = 'WidgetCreated',
    Key? key,
  }) : super(key: key);

  @override
  StatefulElement createElement() {
    MatomoTracker.trackScreenWithName(
      name.isEmpty ? runtimeType.toString() : name,
      title,
    );
    return StatefulElement(this);
  }
}

abstract class TraceableInheritedWidget extends InheritedWidget {
  final String name;
  final String title;

  const TraceableInheritedWidget({
    this.name = '',
    this.title = 'WidgetCreated',
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  InheritedElement createElement() {
    MatomoTracker.trackScreenWithName(
      name.isEmpty ? runtimeType.toString() : name,
      title,
    );
    return InheritedElement(this);
  }
}

class MatomoTracker {
  final log = Logger('Matomo');

  static const kFirstVisit = 'matomo_first_visit';
  static const kLastVisit = 'matomo_last_visit';
  static const kVisitCount = 'matomo_visit_count';
  static const kVisitorId = 'matomo_visitor_id';
  static const kOptOut = 'matomo_opt_out';

  late _MatomoDispatcher _dispatcher;

  static final _instance = MatomoTracker._internal();

  factory MatomoTracker() => _instance;

  MatomoTracker._internal();

  int? siteId;
  String? url;
  late Session session;
  late Visitor visitor;
  String? userAgent;
  String? contentBase;
  int? width;
  int? height;
  String? currentScreenId;

  bool initialized = false;
  bool? _optout = false;

  SharedPreferences? _prefs;

  final _queue = Queue<_Event>();
  late Timer _timer;

  Future<void> initialize({
    required int siteId,
    required String url,
    String? visitorId,
    String? contentBaseUrl,
    int dequeueInterval = 10,
    String? tokenAuth,
  }) async {
    this.siteId = siteId;
    this.url = url;
    String? _visitorId = visitorId;

    _dispatcher = _MatomoDispatcher(url, tokenAuth);

    // User agent
    if (kIsWeb) {
      userAgent = html.window.navigator.userAgent;
    } else {
      try {
        await FkUserAgent.init();
        userAgent = FkUserAgent.webViewUserAgent;
      } catch (_) {
        userAgent = 'Unknown';
      }
    }

    // Screen Resolution
    width = window.physicalSize.width.toInt();
    height = window.physicalSize.height.toInt();

    // Initialize Session Information
    DateTime firstVisit = DateTime.now().toUtc();
    DateTime lastVisit = DateTime.now().toUtc();
    int visitCount = 1;

    _prefs = await SharedPreferences.getInstance();

    if (_prefs!.containsKey(kFirstVisit)) {
      firstVisit =
          DateTime.fromMillisecondsSinceEpoch(_prefs!.getInt(kFirstVisit)!);
    } else {
      _prefs!.setInt(kFirstVisit, firstVisit.millisecondsSinceEpoch);
    }

    if (_prefs!.containsKey(kLastVisit)) {
      lastVisit =
          DateTime.fromMillisecondsSinceEpoch(_prefs!.getInt(kLastVisit)!);
    }
    // Now is the last visit.
    _prefs!.setInt(kLastVisit, lastVisit.millisecondsSinceEpoch);

    if (_prefs!.containsKey(kVisitCount)) {
      visitCount += _prefs!.getInt(kVisitCount)!;
    }
    _prefs!.setInt(kVisitCount, visitCount);

    session = Session(
      firstVisit: firstVisit,
      lastVisit: lastVisit,
      visitCount: visitCount,
    );

    // Initialize Visitor
    if (_visitorId == null) {
      _visitorId = const Uuid().v4();
      if (_prefs!.containsKey(kVisitorId)) {
        _visitorId = _prefs?.getString(kVisitorId);
      } else {
        _prefs?.setString(kVisitorId, _visitorId);
      }
    }
    visitor = Visitor(id: _visitorId, userId: _visitorId);

    if (contentBaseUrl != null) {
      contentBase = contentBaseUrl;
    } else if (kIsWeb) {
      contentBase = html.window.location.href;
    } else {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      contentBase = 'https://${packageInfo.packageName}';
    }

    if (_prefs!.containsKey(kOptOut)) {
      _optout = _prefs!.getBool(kOptOut);
    } else {
      _prefs!.setBool(kOptOut, _optout!);
    }

    log.fine(
      'Matomo Initialized: firstVisit=$firstVisit; lastVisit=$lastVisit; visitCount=$visitCount; visitorId=$visitorId; contentBase=$contentBase; resolution=${width}x$height; userAgent=$userAgent',
    );
    initialized = true;

    _timer = Timer.periodic(Duration(seconds: dequeueInterval), (timer) {
      _dequeue();
    });
  }

  bool? get optOut => _optout;

  void setOptOut({required bool optout}) {
    _optout = optout;
    _prefs!.setBool(kOptOut, _optout!);
  }

  void clear() {
    if (_prefs != null) {
      _prefs!.remove(kFirstVisit);
      _prefs!.remove(kLastVisit);
      _prefs!.remove(kVisitCount);
      _prefs!.remove(kVisitorId);
    }
  }

  void dispose() {
    _timer.cancel();
  }

  static void dispatchEvents() {
    final tracker = MatomoTracker();
    if (tracker.initialized) {
      tracker._dequeue();
    }
  }

  static void trackScreen(BuildContext context, String eventName) {
    final widgetName = context.widget.toStringShort();
    trackScreenWithName(widgetName, eventName);
  }

  static void trackScreenWithName(String widgetName, String eventName) {
    // From https://gitlab.com/petleo-and-iatros-opensource/flutter_matomo/blob/master/lib/flutter_matomo.dart
    // trackScreen(widgetName: widgetName, eventName: eventName);
    // -> track().screen(widgetName).with(tracker)
    // -> Event(action:)
    final tracker = MatomoTracker();
    tracker.currentScreenId = randomAlphaNumeric(6);
    tracker._track(
      _Event(
        tracker: tracker,
        action: widgetName,
      ),
    );
  }

  static void trackGoal(int goalId, {double? revenue}) {
    final tracker = MatomoTracker();
    tracker._track(
      _Event(
        tracker: tracker,
        goalId: goalId,
        revenue: revenue,
      ),
    );
  }

  static void trackEvent(
    String eventName,
    String eventAction, {
    String? widgetName,
    int? eventValue,
  }) {
    final tracker = MatomoTracker();
    tracker._track(
      _Event(
        tracker: tracker,
        eventAction: eventAction,
        eventName: eventName,
        eventCategory: widgetName,
        eventValue: eventValue,
      ),
    );
  }

  static void trackCartUpdate(
    List<TrackingOrderItem>? trackingOrderItems,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount,
  ) {
    final tracker = MatomoTracker();
    tracker._track(
      _Event(
        tracker: tracker,
        goalId: 0,
        trackingOrderItems: trackingOrderItems,
        subTotal: subTotal,
        taxAmount: taxAmount,
        shippingCost: shippingCost,
        discountAmount: discountAmount,
      ),
    );
  }

  static void trackOrder(
    String? orderId,
    List<TrackingOrderItem>? trackingOrderItems,
    num? revenue,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount,
  ) {
    final tracker = MatomoTracker();
    tracker._track(
      _Event(
        tracker: tracker,
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

  void _track(_Event event) {
    _queue.add(event);
  }

  void _dequeue() {
    assert(initialized);
    log.finest('Processing queue ${_queue.length}');
    while (_queue.isNotEmpty) {
      final event = _queue.removeFirst();
      if (!_optout!) {
        _dispatcher.send(event);
      }
    }
  }
}

class Session {
  final DateTime? firstVisit;
  final DateTime? lastVisit;
  final int? visitCount;

  Session({this.firstVisit, this.lastVisit, this.visitCount});
}

class Visitor {
  final String? id;
  final String? forcedId;
  final String? userId;

  Visitor({this.id, this.forcedId, this.userId});
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

  List<dynamic> toArray() => [
        sku,
        name,
        category,
        price,
        quantity,
      ];
}

class _Event {
  final MatomoTracker tracker;
  final String? action;
  final String? eventCategory;
  final String? eventAction;
  final String? eventName;
  final int? eventValue;
  final int? goalId;

  // Ecommerce
  final String? orderId;
  final List<TrackingOrderItem>? trackingOrderItems;
  final num? revenue;
  final num? subTotal; // Excludes shipping
  final num? taxAmount;
  final num? shippingCost;
  final num? discountAmount;

  late DateTime _date;

  _Event({
    required this.tracker,
    this.action,
    this.eventCategory,
    this.eventAction,
    this.eventName,
    this.eventValue,
    this.goalId,
    this.orderId,
    this.trackingOrderItems,
    this.revenue,
    this.subTotal,
    this.taxAmount,
    this.shippingCost,
    this.discountAmount,
  }) {
    _date = DateTime.now().toUtc();
  }

  Map<String, dynamic> toMap() {
    // Based from https://developer.matomo.org/api-reference/tracking-api
    // https://github.com/matomo-org/matomo-sdk-ios/blob/develop/MatomoTracker/EventAPISerializer.swift
    final map = <String, dynamic>{};
    map['idsite'] = tracker.siteId.toString();
    map['rec'] = 1;

    map['rand'] = Random().nextInt(1000000000);
    map['apiv'] = 1;
    map['cookie'] = 1;

    // Visitor
    map['_id'] = tracker.visitor.id;
    if (tracker.visitor.forcedId != null) {
      map['cid'] = tracker.visitor.forcedId;
    }
    map['uid'] = tracker.visitor.userId;

    if (tracker.currentScreenId != null) {
      map['pv_id'] = tracker.currentScreenId;
    }

    // Session
    map['_idvc'] = tracker.session.visitCount.toString();
    map['_viewts'] = tracker.session.lastVisit!.millisecondsSinceEpoch ~/ 1000;
    map['_idts'] = tracker.session.firstVisit!.millisecondsSinceEpoch ~/ 1000;

    if (action != null) {
      map['url'] = '${tracker.contentBase}/$action';
    } else {
      map['url'] = '${tracker.contentBase}';
    }

    map['action_name'] = action;

    final locale = window.locale;
    map['lang'] = locale.toString();

    map['h'] = _date.hour.toString();
    map['m'] = _date.minute.toString();
    map['s'] = _date.second.toString();
    map['cdt'] = _date.toIso8601String();

    // Screen Resolution
    map['res'] = '${tracker.width}x${tracker.height}';

    // Goal
    if (goalId != null) {
      map['idgoal'] = goalId;
    }
    if (revenue != null && revenue! > 0) {
      map['revenue'] = revenue;
    }

    // Event
    if (eventCategory != null) {
      map['e_c'] = eventCategory;
    }
    if (eventAction != null) {
      map['e_a'] = eventAction;
    }
    if (eventName != null) {
      map['e_n'] = eventName;
    }
    if (eventValue != null) {
      map['e_v'] = eventValue;
    }

    // Ecommerce
    if (orderId != null) {
      map['ec_id'] = orderId;
    }
    if (trackingOrderItems != null) {
      map['ec_items'] =
          json.encode(trackingOrderItems!.map((i) => i.toArray()).toList());
    }
    if (subTotal != null) {
      map['ec_st'] = subTotal;
    }
    if (taxAmount != null) {
      map['ec_tx'] = taxAmount;
    }
    if (shippingCost != null) {
      map['ec_sh'] = shippingCost;
    }
    if (discountAmount != null) {
      map['ec_dt'] = discountAmount;
    }

    return map;
  }
}

class _MatomoDispatcher {
  final String baseUrl;
  final String? tokenAuth;

  _MatomoDispatcher(this.baseUrl, this.tokenAuth);

  void send(_Event event) {
    final headers = <String, String>{
      if (!kIsWeb && event.tracker.userAgent != null)
        'User-Agent': event.tracker.userAgent!,
    };

    final map = event.toMap();
    final buffer = StringBuffer('$baseUrl?');
    for (final key in map.keys) {
      final value = Uri.encodeComponent(map[key].toString());
      buffer.write('$key=$value&');
    }
    if (tokenAuth != null) {
      buffer.write('token_auth=$tokenAuth');
    }
    event.tracker.log.fine(' -> ${buffer.toString()}');
    http
        .post(Uri.parse(buffer.toString()), headers: headers)
        .then((http.Response response) {
      final int statusCode = response.statusCode;
      event.tracker.log.fine(' <- $statusCode');
      if (statusCode != 200) {}
    }).catchError((e) {
      event.tracker.log.fine(' <- ${e.toString()}');
    });
  }
}
