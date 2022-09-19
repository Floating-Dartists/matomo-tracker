import 'package:flutter/material.dart';

import '../matomo_tracker.dart';

/// Register a `trackScreenWithName` on this widget.
@optionalTypeArgs
mixin TraceableClientMixin<T extends StatefulWidget> on State<T> {
  /// {@template traceableClientMixin.traceName}
  /// Equivalent to an event action. (e.g. `'Created HomePage'`)
  /// {@endtemplate}
  @protected
  String get traceName => 'Created widget ${widget.toStringShort()}';

  /// {@template traceableClientMixin.traceTitle}
  /// Equivalent to an event name. (e.g. `'HomePage'`)
  /// {@endtemplate}
  @protected
  String get traceTitle;

  /// {@template traceableClientMixin.widgetId}
  /// A 6 character unique ID. If `null`, a random id will be generated.
  /// {@endtemplate}
  @protected
  String? widgetId;

  /// {@template traceableClientMixin.path}
  /// Path to the widget. (e.g. `'/home'`)
  /// {@endtemplate}
  @protected
  String? path;

  /// {@template traceableClientMixin.tracker}
  /// Matomo instance used to send events.
  ///
  /// By default it uses the global [MatomoTracker.instance].
  /// {@endtemplate}
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
      path: path,
    );
  }
}
