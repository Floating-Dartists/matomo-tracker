import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import '../matomo_tracker.dart';

class MatomoEvent {
  final MatomoTracker tracker;
  final String? action;
  final String? eventCategory;
  final String? eventAction;
  final String? eventName;
  final int? eventValue;
  final int? goalId;
  final String? orderId;
  final List<TrackingOrderItem>? trackingOrderItems;
  final num? revenue;

  /// Excludes shipping
  final num? subTotal;

  final num? taxAmount;
  final num? shippingCost;
  final num? discountAmount;
  final DateTime _date;

  MatomoEvent({
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
  }) : _date = DateTime.now().toUtc();

  Map<String, String> toMap() {
    final id = tracker.visitor.id;
    final cid = tracker.visitor.forcedId;
    final uid = tracker.visitor.userId;
    final pvId = tracker.currentScreenId;
    final actionName = action;
    final url = actionName != null
        ? '${tracker.contentBase}/$actionName'
        : tracker.contentBase;
    final idgoal = goalId;
    final _revenue = revenue;
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

    return {
      'idsite': tracker.siteId.toString(),
      'rec': '1',
      'rand': '${Random().nextInt(1000000000)}',
      'apiv': '1',
      'cookie': '1',
      if (id != null) '_id': id,
      if (cid != null) 'cid': cid,
      if (uid != null) 'uid': uid,
      if (pvId != null) 'pv_id': pvId,
      '_idvc': tracker.session.visitCount.toString(),
      '_viewts': '${tracker.session.lastVisit.millisecondsSinceEpoch ~/ 1000}',
      '_idts': '${tracker.session.firstVisit.millisecondsSinceEpoch ~/ 1000}',
      'url': url,
      if (actionName != null) 'action_name': actionName,
      'lang': window.locale.toString(),
      'h': _date.hour.toString(),
      'm': _date.minute.toString(),
      's': _date.second.toString(),
      'cdt': _date.toIso8601String(),
      'res': '${tracker.width}x${tracker.height}',
      if (idgoal != null) 'idgoal': idgoal.toString(),
      if (_revenue != null && _revenue > 0) 'revenue': _revenue.toString(),
      if (eC != null) 'e_c': eC,
      if (eA != null) 'e_a': eA,
      if (eN != null) 'e_n': eN,
      if (eV != null) 'e_v': eV.toString(),
      if (ecId != null) 'ec_id': ecId,
      if (ecItems != null)
        'ec_items': jsonEncode(ecItems.map((i) => i.toArray()).toList()),
      if (ecSt != null) 'ec_st': ecSt.toString(),
      if (ecTx != null) 'ec_tx': ecTx.toString(),
      if (ecSh != null) 'ec_sh': ecSh.toString(),
      if (ecDt != null) 'ec_dt': ecDt.toString(),
      if (ua != null) 'ua': ua,
    };
  }
}
