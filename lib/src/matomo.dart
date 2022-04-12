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

const _kFirstVisit = 'matomo_first_visit';
const _kLastVisit = 'matomo_last_visit';
const _kVisitCount = 'matomo_visit_count';
const _kVisitorId = 'matomo_visitor_id';
const _kOptOut = 'matomo_opt_out';

class MatomoTracker {
  final log = Logger('Matomo');

  late _MatomoDispatcher _dispatcher;

  static final instance = MatomoTracker._internal();

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

    if (_prefs!.containsKey(_kFirstVisit)) {
      firstVisit =
          DateTime.fromMillisecondsSinceEpoch(_prefs!.getInt(_kFirstVisit)!);
    } else {
      _prefs!.setInt(_kFirstVisit, firstVisit.millisecondsSinceEpoch);
    }

    if (_prefs!.containsKey(_kLastVisit)) {
      lastVisit =
          DateTime.fromMillisecondsSinceEpoch(_prefs!.getInt(_kLastVisit)!);
    }
    // Now is the last visit.
    _prefs!.setInt(_kLastVisit, lastVisit.millisecondsSinceEpoch);

    if (_prefs!.containsKey(_kVisitCount)) {
      visitCount += _prefs!.getInt(_kVisitCount)!;
    }
    _prefs!.setInt(_kVisitCount, visitCount);

    session = Session(
      firstVisit: firstVisit,
      lastVisit: lastVisit,
      visitCount: visitCount,
    );

    // Initialize Visitor
    if (_visitorId == null) {
      _visitorId = const Uuid().v4();
      if (_prefs!.containsKey(_kVisitorId)) {
        _visitorId = _prefs?.getString(_kVisitorId);
      } else {
        _prefs?.setString(_kVisitorId, _visitorId);
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

    if (_prefs!.containsKey(_kOptOut)) {
      _optout = _prefs!.getBool(_kOptOut);
    } else {
      _prefs!.setBool(_kOptOut, _optout!);
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
    _prefs!.setBool(_kOptOut, _optout!);
  }

  void clear() {
    if (_prefs != null) {
      _prefs!.remove(_kFirstVisit);
      _prefs!.remove(_kLastVisit);
      _prefs!.remove(_kVisitCount);
      _prefs!.remove(_kVisitorId);
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

  void trackScreen(BuildContext context, String eventName) {
    final widgetName = context.widget.toStringShort();
    trackScreenWithName(widgetName, eventName);
  }

  void trackScreenWithName(String widgetName, String eventName) {
    // From https://gitlab.com/petleo-and-iatros-opensource/flutter_matomo/blob/master/lib/flutter_matomo.dart
    // trackScreen(widgetName: widgetName, eventName: eventName);
    // -> track().screen(widgetName).with(tracker)
    // -> Event(action:)
    currentScreenId = randomAlphaNumeric(6);
    _track(
      _Event(
        tracker: this,
        action: widgetName,
      ),
    );
  }

  void trackGoal(int goalId, {double? revenue}) {
    _track(
      _Event(
        tracker: this,
        goalId: goalId,
        revenue: revenue,
      ),
    );
  }

  void trackEvent(
    String eventName,
    String eventAction, {
    String? widgetName,
    int? eventValue,
  }) {
    _track(
      _Event(
        tracker: this,
        eventAction: eventAction,
        eventName: eventName,
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
    _track(
      _Event(
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
    _track(
      _Event(
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
