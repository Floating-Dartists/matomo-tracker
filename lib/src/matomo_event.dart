import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:matomo_tracker/utils/extensions.dart';

class MatomoEvent {
  MatomoEvent({
    this.path,
    this.action,
    this.eventInfo,
    this.screenId,
    this.goalId,
    this.orderId,
    this.trackingOrderItems,
    this.revenue,
    this.subTotal,
    this.taxAmount,
    this.shippingCost,
    this.discountAmount,
    this.searchKeyword,
    this.searchCategory,
    this.searchCount,
    this.link,
    this.campaign,
    this.dimensions,
    this.newVisit,
    this.ping,
    this.content,
    this.contentInteraction,
    this.performanceInfo,
  })  :
        // we use clock.now instead of DateTime.now to make testing easier
        _date = clock.now().toUtc(),
        assert(
          screenId == null || screenId.length == 6,
          'screenId has to be six characters long',
        );

  final String? path;

  /// The title of the action being tracked. It is possible to use slashes / to
  /// set one or several categories for this action. For example, **Help /
  /// Feedback** will create the Action **Feedback** in the category **Help**.
  final String? action;

  final EventInfo? eventInfo;

  /// 6 character unique ID that identifies which actions were performed on a
  /// specific page view.
  final String? screenId;

  final int? goalId;
  final String? orderId;
  final List<TrackingOrderItem>? trackingOrderItems;
  final num? revenue;

  /// Excludes shipping
  final num? subTotal;

  final num? taxAmount;
  final num? shippingCost;
  final num? discountAmount;

  /// The current time.
  final DateTime _date;

  /// The search keyword
  final String? searchKeyword;

  /// The selected categories for search
  final String? searchCategory;

  /// The count of shown results
  final int? searchCount;

  final String? link;

  final Campaign? campaign;

  // The dimensions associated with the event
  final Map<String, String>? dimensions;

  final bool? newVisit;

  final bool? ping;

  final Content? content;
  final String? contentInteraction;

  final PerformanceInfo? performanceInfo;

  MatomoEvent copyWith({
    String? path,
    String? action,
    EventInfo? eventInfo,
    String? screenId,
    int? goalId,
    String? orderId,
    List<TrackingOrderItem>? trackingOrderItems,
    num? revenue,
    num? subTotal,
    num? taxAmount,
    num? shippingCost,
    num? discountAmount,
    String? searchKeyword,
    String? searchCategory,
    int? searchCount,
    String? link,
    Campaign? campaign,
    Map<String, String>? dimensions,
    bool? newVisit,
    bool? ping,
    Content? content,
    String? contentInteraction,
    PerformanceInfo? performanceInfo,
  }) =>
      MatomoEvent(
        path: path ?? this.path,
        action: action ?? this.action,
        eventInfo: eventInfo ?? this.eventInfo,
        screenId: screenId ?? this.screenId,
        goalId: goalId ?? this.goalId,
        orderId: orderId ?? this.orderId,
        trackingOrderItems: trackingOrderItems ?? this.trackingOrderItems,
        revenue: revenue ?? this.revenue,
        subTotal: subTotal ?? this.subTotal,
        taxAmount: taxAmount ?? this.taxAmount,
        shippingCost: shippingCost ?? this.shippingCost,
        discountAmount: discountAmount ?? this.discountAmount,
        searchKeyword: searchKeyword ?? this.searchKeyword,
        searchCategory: searchCategory ?? this.searchCategory,
        searchCount: searchCount ?? this.searchCount,
        link: link ?? this.link,
        campaign: campaign ?? this.campaign,
        dimensions: dimensions ?? this.dimensions,
        newVisit: newVisit ?? this.newVisit,
        ping: ping ?? this.ping,
        content: content ?? this.content,
        contentInteraction: contentInteraction ?? this.contentInteraction,
        performanceInfo: performanceInfo ?? this.performanceInfo,
      );

  Map<String, String> toMap(MatomoTracker tracker) {
    final id = tracker.visitor.id;
    final uid = tracker.visitor.uid;
    final pvId = screenId;
    final actionName = action;
    final camp = campaign;
    final campKeyword = camp?.keyword;
    final localPath = path;
    final uri = Uri.parse(
      localPath != null
          ? '${tracker.contentBase}${localPath.prefixWithSlash()}'
          : tracker.contentBase,
    );
    final url = uri.replace(
      queryParameters: {
        if (camp != null) ...camp.toMap(),
        ...uri.queryParameters,
      },
    ).toString();
    final idgoal = goalId;
    final aRevenue = revenue;
    final event = eventInfo;
    final ecId = orderId;
    final ecItems = trackingOrderItems;
    final ecSt = subTotal;
    final ecTx = taxAmount;
    final ecSh = shippingCost;
    final ecDt = discountAmount;
    final ua = tracker.userAgent;
    final dims = dimensions;
    final locale = PlatformDispatcher.instance.locale;
    final country = locale.countryCode;
    final nV = newVisit;
    final p = ping;
    final cont = content;
    final contInteraction = contentInteraction;
    // According to documentation, pings should not have the ca parameter
    final ca = (event != null || content != null) && !(p ?? false);
    // We don't need to send the performance info again if this is a ping
    final perfInfo = (p ?? false) ? null : performanceInfo;

    return {
      // Required parameters
      'idsite': tracker.siteId.toString(),
      'rec': '1',

      if (nV != null && nV) 'new_visit': '1',

      if (p != null && p) 'ping': '1',

      if (ca) 'ca': '1',

      // Recommended parameters
      if (actionName != null) 'action_name': actionName,
      'url': url,
      if (camp != null) '_rcn': camp.name,
      if (campKeyword != null) '_rck': campKeyword,
      if (id != null) '_id': id,
      'rand': '${Random().nextInt(1000000000)}',
      'apiv': '1',

      // Optional User info
      '_idvc': tracker.session.visitCount.toString(),
      '_viewts': '${tracker.session.lastVisit.millisecondsSinceEpoch ~/ 1000}',
      '_idts': '${tracker.session.firstVisit.millisecondsSinceEpoch ~/ 1000}',
      'res':
          '${tracker.screenResolution.width.toInt()}x${tracker.screenResolution.height.toInt()}',
      'h': _date.hour.toString(),
      'm': _date.minute.toString(),
      's': _date.second.toString(),
      'cookie': '1',
      if (ua != null) 'ua': ua,
      'lang': locale.toString(),
      if (country != null && tracker.getAuthToken != null) 'country': country,

      if (uid != null) 'uid': uid,

      // Optional Action info (measure Page view, Outlink, Download, Site search)
      if (pvId != null) 'pv_id': pvId,
      if (idgoal != null) 'idgoal': idgoal.toString(),

      // Optional Event Tracking info
      if (event != null) ...event.toMap(),

      // Optional Ecommerce info
      if (ecId != null) 'ec_id': ecId,
      if (ecItems != null)
        'ec_items': jsonEncode(ecItems.map((i) => i.toArray()).toList()),
      if (aRevenue != null && aRevenue > 0) 'revenue': aRevenue.toString(),
      if (ecSt != null) 'ec_st': ecSt.toString(),
      if (ecTx != null) 'ec_tx': ecTx.toString(),
      if (ecSh != null) 'ec_sh': ecSh.toString(),
      if (ecDt != null) 'ec_dt': ecDt.toString(),

      if (searchKeyword != null) 'search': searchKeyword!,
      if (searchCategory != null) 'search_cat': searchCategory!,
      if (searchCount != null) 'search_count': searchCount!.toString(),

      if (link != null) 'link': link!,

      // Other parameters (require authentication via `token_auth`)
      'cdt': _date.toIso8601String(),

      if (cont != null) ...cont.toMap(),
      if (contInteraction != null) 'c_i': contInteraction,

      if (perfInfo != null) ...perfInfo.toMap(),

      if (dims != null) ...dims,
    };
  }
}
