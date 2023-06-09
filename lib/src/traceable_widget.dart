import 'package:flutter/material.dart';

import 'package:matomo_tracker/matomo_tracker.dart';

/// Wrapper around [TraceableClientMixin] to easily track a [child] widget.
class TraceableWidget extends StatefulWidget {
  const TraceableWidget({
    super.key,
    required this.child,
    this.actionName,
    this.pvId,
    this.updatePvIdAfterPop,
    this.path,
    this.dimensions,
    this.campaign,
    this.tracker,
    this.performanceInfo,
  });

  /// {@macro traceableClientMixin.actionName}
  final String? actionName;

  /// {@macro traceableClientMixin.pvId}
  final String? pvId;

  /// {@macro traceableClientMixin.updatePvIdAfterPop}
  final bool? updatePvIdAfterPop;

  /// {@macro traceableClientMixin.path}
  final String? path;

  /// {@macro traceableClientMixin.campaign}
  final Campaign? campaign;

  /// {@macro traceableClientMixin.dimensions}
  final Map<String, String>? dimensions;

  /// {@macro traceableClientMixin.performanceInfo}
  final PerformanceInfo? performanceInfo;

  /// {@macro traceableClientMixin.tracker}
  final MatomoTracker? tracker;

  final Widget child;

  @override
  State<TraceableWidget> createState() => _TraceableWidgetState();
}

class _TraceableWidgetState extends State<TraceableWidget>
    with TraceableClientMixin {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  String get actionName => widget.actionName ?? super.actionName;

  @override
  String get pvId => widget.pvId ?? super.pvId;

  @override
  bool get updatePvIdAfterPop =>
      widget.updatePvIdAfterPop ?? super.updatePvIdAfterPop;

  @override
  String? get path => widget.path;

  @override
  Campaign? get campaign => widget.campaign;

  @override
  Map<String, String>? get dimensions => widget.dimensions;

  @override
  PerformanceInfo? get performanceInfo => widget.performanceInfo;

  @override
  MatomoTracker get tracker => widget.tracker ?? super.tracker;
}
