import 'package:flutter/material.dart';

import 'package:matomo_tracker/matomo_tracker.dart';

/// Wrapper around [TraceableClientMixin] to easily track a [child] widget.
class TraceableWidget extends StatefulWidget {
  const TraceableWidget({
    super.key,
    required this.child,
    required this.eventName,
    this.eventCategory,
    this.actionName,
    this.pvId,
    this.path,
    this.tracker,
  });

  /// {@macro traceableClientMixin.actionName}
  final String? actionName;

  /// {@macro traceableClientMixin.eventName}
  final String eventName;

  /// {@macro traceableClientMixin.eventCategory}
  final String? eventCategory;

  /// {@macro traceableClientMixin.pvId}
  final String? pvId;

  /// {@macro traceableClientMixin.path}
  final String? path;

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
  String get eventName => widget.eventName;

  @override
  String get eventCategory => widget.eventCategory ?? super.eventCategory;

  @override
  String? get pvId => widget.pvId;

  @override
  String? get path => widget.path;

  @override
  MatomoTracker get tracker => widget.tracker ?? super.tracker;
}
