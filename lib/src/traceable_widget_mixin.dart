import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

/// Register a `trackScreenWithName` on this widget.
@optionalTypeArgs
mixin TraceableClientMixin<T extends StatefulWidget> on State<T> {
  /// {@template traceableClientMixin.actionName}
  /// Equivalent to an event action. (e.g. `'Created HomePage'`).
  /// {@endtemplate}
  @protected
  String get actionName => 'Created widget ${widget.toStringShort()}';

  /// {@template traceableClientMixin.traceTitle}
  /// Equivalent to an event name. (e.g. `'HomePage'`).
  ///
  /// This corresponds with `e_n`.
  /// {@endtemplate}
  @protected
  String get traceTitle;

  /// {@template traceableClientMixin.widgetId}
  /// A 6 character unique ID. If `null`, a random id will be generated.
  ///
  /// This corresponds with `pv_id`.
  /// {@endtemplate}
  @protected
  String? widgetId;

  /// {@template traceableClientMixin.path}
  /// Path to the widget. (e.g. `'/home'`).
  ///
  /// This will be combined with [MatomoTracker.contentBase]. The combination
  /// corresponds with `url`.
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
      actionName: actionName,
      eventName: traceTitle,
      currentScreenId: widgetId,
      path: path,
    );
  }
}
