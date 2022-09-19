import 'package:flutter/material.dart';

import 'traceable_widget_mixin.dart';

/// Wrapper around [TraceableClientMixin] to easily track a [child] widget.
class TraceableWidget extends StatefulWidget {
  /// {@macro traceableClientMixin.traceName}
  final String? traceName;

  final String traceTitle;
  final Widget child;

  const TraceableWidget({
    Key? key,
    this.traceName,
    required this.traceTitle,
    required this.child,
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
}
