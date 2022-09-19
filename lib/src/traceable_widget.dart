import 'package:flutter/material.dart';

import '../matomo_tracker.dart';

/// Wrapper around [TraceableClientMixin] to easily track a [child] widget.
class TraceableWidget extends StatefulWidget {
  /// {@macro traceableClientMixin.traceName}
  final String? traceName;

  /// {@macro traceableClientMixin.traceTitle}
  final String traceTitle;

  /// {@macro traceableClientMixin.widgetId}
  final String? widgetId;

  /// {@macro traceableClientMixin.path}
  final String? path;

  /// {@macro traceableClientMixin.tracker}
  final MatomoTracker? tracker;

  final Widget child;

  const TraceableWidget({
    required this.child,
    required this.traceTitle,
    Key? key,
    this.traceName,
    this.widgetId,
    this.path,
    this.tracker,
  }) : super(key: key);

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
  String get traceName => widget.traceName ?? super.traceName;

  @override
  String get traceTitle => widget.traceTitle;

  @override
  String? get widgetId => widget.widgetId;

  @override
  String? get path => widget.path;

  @override
  MatomoTracker get tracker => widget.tracker ?? super.tracker;
}
