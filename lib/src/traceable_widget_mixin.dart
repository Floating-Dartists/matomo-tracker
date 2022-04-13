import 'package:flutter/material.dart';

import '../matomo_tracker.dart';

/// Register a `trackScreenWithName` on this widget.
@optionalTypeArgs
mixin TraceableClientMixin<T extends StatefulWidget> on State<T> {
  /// Equivalent to an event action. (e.g. `'Created HomePage'`)
  @protected
  String get traceName;

  /// Equivalent to an event name. (e.g. `'HomePage'`)
  @protected
  String get traceTitle;

  @protected
  String get widgetId => widget.toStringShort();

  /// Matomo instance used to send events.
  ///
  /// By default it uses the global [MatomoTracker.instance].
  @protected
  MatomoTracker get tracker => MatomoTracker.instance;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    tracker.trackScreenWithName(
      widgetName: traceName,
      eventName: traceTitle,
      currentScreenId: widgetId,
    );
  }
}
