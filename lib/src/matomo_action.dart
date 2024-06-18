import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:matomo_tracker/utils/extensions.dart';

class MatomoAction {
  MatomoAction({
    this.path,
    this.action,
    this.eventInfo,
    this.pvId,
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
          pvId == null || pvId.length == 6,
          'pvId has to be six characters long',
        );

  final String? path;

  /// The title of the action being tracked. It is possible to use slashes / to
  /// set one or several categories for this action. For example, **Help /
  /// Feedback** will create the Action **Feedback** in the category **Help**.
  final String? action;

  final EventInfo? eventInfo;

  /// 6 character unique ID that identifies which actions were performed on a
  /// specific page view.
  final String? pvId;

  ///  If specified, the tracking request will trigger a conversion for the
  /// [goal](https://matomo.org/guide/reports/goals-and-conversions/) of the
  /// website being tracked with this ID.
  final int? goalId;

  /// The unique string identifier for the ecommerce order (required when
  /// tracking an ecommerce order)
  final String? orderId;

  /// Items in the Ecommerce order.
  final List<TrackingOrderItem>? trackingOrderItems;

  /// Used either as a monetary value when tracking a goal or as the total of
  /// an ecommerce order.
  final double? revenue;

  /// Sub total of an order; excludes shipping.
  final num? subTotal;

  /// Tax amount of an order.
  final num? taxAmount;

  /// Shipping cost of an order.
  final num? shippingCost;

  /// Discount offered for an order.
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

  // The dimensions associated with the action
  final Map<String, String>? dimensions;

  final bool? newVisit;

  final bool? ping;

  final Content? content;
  final String? contentInteraction;

  final PerformanceInfo? performanceInfo;

  MatomoAction copyWith({
    String? path,
    String? action,
    EventInfo? eventInfo,
    String? pvId,
    int? goalId,
    String? orderId,
    List<TrackingOrderItem>? trackingOrderItems,
    double? revenue,
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
      MatomoAction(
        path: path ?? this.path,
        action: action ?? this.action,
        eventInfo: eventInfo ?? this.eventInfo,
        pvId: pvId ?? this.pvId,
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
    final pvId = this.pvId;
    final actionName = action;
    final camp = campaign;
    final campKeyword = camp?.keyword;
    final localPath = path;

    final baseUrl = (localPath != null
            ? '${tracker.contentBase.removeTrailingSlash()}${localPath.prefixWithSlash()}'
            : tracker.contentBase)
        .replaceHashtags();
    final uri = Uri.parse(baseUrl);
    final url = uri
        .replace(
          queryParameters: camp != null || uri.queryParameters.isNotEmpty
              ? {
                  if (camp != null) ...camp.toMap(),
                  ...uri.queryParameters,
                }
              : null,
        )
        .toString()
        .restoreHashtags();
    final idgoal = goalId;
    final aRevenue = revenue;
    final event = eventInfo;
    final ecId = orderId;
    final ecItems = trackingOrderItems;
    final ecSt = subTotal;
    final ecTx = taxAmount;
    final ecSh = shippingCost;
    final ecDt = discountAmount;
    final search = searchKeyword;
    final searchCat = searchCategory;
    final searchCount = this.searchCount;
    final link = this.link;
    final ua = tracker.userAgent;
    final dims = dimensions;
    final locale = PlatformDispatcher.instance.locale;
    final country = locale.countryCode?.toLowerCase();
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
      'idsite': tracker.siteId,
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
      if (country != null && tracker.authToken != null) 'country': country,
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
      if (search != null) 'search': search,
      if (searchCat != null) 'search_cat': searchCat,
      if (searchCount != null) 'search_count': searchCount.toString(),
      if (link != null) 'link': link,

      // Other parameters (require authentication via `token_auth`)
      'cdt': _date.toIso8601String(),

      if (cont != null) ...cont.toMap(),
      if (contInteraction != null) 'c_i': contInteraction,

      if (perfInfo != null) ...perfInfo.toMap(),

      if (dims != null) ...dims,
    };
  }
}

extension on String {
  String removeTrailingSlash() {
    if (endsWith('/')) return substring(0, length - 1);
    return this;
  }

  static const _placeholder = 'HASHTAG_PLACEHOLDER';
  String replaceHashtags() => replaceAll('/#/', '/$_placeholder/');
  String restoreHashtags() => replaceAll('/$_placeholder/', '/#/');
}
