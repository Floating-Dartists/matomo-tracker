import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'matomo.dart';
import 'tracking_order_item.dart';

class MatomoEvent {
  final MatomoTracker tracker;
  final String? path;

  /// The title of the action being tracked. It is possible to use slashes / to
  /// set one or several categories for this action. For example, **Help /
  /// Feedback** will create the Action **Feedback** in the category **Help**.
  final String? action;

  /// The event category. Must not be empty. (eg. Videos, Music, Games...)
  final String? eventCategory;

  /// The event action. Must not be empty. (eg. Play, Pause, Duration, Add
  /// Playlist, Downloaded, Clicked...)
  final String? eventAction;

  /// The event name. (eg. a Movie name, or Song name, or File name...)
  final String? eventName;

  /// The event value.
  final num? eventValue;

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

  // The dimensions associated with the event
  final Map<String, String>? dimensions;

  MatomoEvent({
    required this.tracker,
    this.path,
    this.action,
    this.eventCategory,
    this.eventAction,
    this.eventName,
    this.eventValue,
    String? screenId,
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
    this.dimensions,
  })  : _date = DateTime.now().toUtc(),
        screenId = screenId ?? tracker.currentScreenId,
        assert(
          screenId == null || screenId.length == 6,
          'screenId has to be six characters long',
        ),
        assert(
          eventCategory == null || eventCategory.isNotEmpty,
          'eventCategory must not be empty',
        ),
        assert(
          eventAction == null || eventAction.isNotEmpty,
          'eventAction must not be empty',
        ),
        assert(
          eventName == null || eventName.isNotEmpty,
          'eventName must not be empty',
        );

  Map<String, String> toMap() {
    final id = tracker.visitor.id;
    final cid = tracker.visitor.forcedId;
    final uid = tracker.visitor.userId;
    final pvId = screenId;
    final actionName = action;
    final url =
        path != null ? '${tracker.contentBase}/$path' : tracker.contentBase;
    final idgoal = goalId;
    final aRevenue = revenue;
    final eC = eventCategory;
    final eA = eventAction;
    final eN = eventName;
    final eV = eventValue;
    final ecId = orderId;
    final ecItems = trackingOrderItems;
    final ecSt = subTotal;
    final ecTx = taxAmount;
    final ecSh = shippingCost;
    final ecDt = discountAmount;
    final ua = tracker.userAgent;
    final country = window.locale.countryCode;
    final dims = dimensions ?? {};

    return {
      // Required parameters
      'idsite': tracker.siteId.toString(),
      'rec': '1',

      // Recommended parameters
      if (actionName != null) 'action_name': actionName,
      'url': url,
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
      'lang': window.locale.toString(),
      if (country != null && tracker.getAuthToken != null) 'country': country,

      if (uid != null) 'uid': uid,
      if (cid != null) 'cid': cid,

      // Optional Action info (measure Page view, Outlink, Download, Site search)
      if (pvId != null) 'pv_id': pvId,
      if (idgoal != null) 'idgoal': idgoal.toString(),

      // Optional Event Tracking info
      if (eC != null) 'e_c': eC,
      if (eA != null) 'e_a': eA,
      if (eN != null) 'e_n': eN,
      if (eV != null) 'e_v': eV.toString(),

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
    }..addAll(dims);
  }
}
