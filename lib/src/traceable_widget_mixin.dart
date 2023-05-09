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

  /// {@template traceableClientMixin.pvId}
  /// A 6 character unique ID. If `null`, a random id will be generated.
  /// {@endtemplate}
  @protected
  String? pvId;

  /// {@template traceableClientMixin.path}
  /// Path to the widget. (e.g. `'/home'`).
  ///
  /// This will be combined with [MatomoTracker.contentBase]. The combination
  /// corresponds with `url`.
  /// {@endtemplate}
  @protected
  String? path;

  /// {@template traceableClientMixin.campaign}
  /// The campaign that lead to this interaction or `null` for a
  /// default entry.
  /// {@endtemplate}
  @protected
  Campaign? campaign;

  /// {@template traceableClientMixin.dimensions}
  /// A Custom Dimension value for a specific Custom Dimension ID.
  ///
  /// If Custom Dimension ID is 2 use `dimension2=dimensionValue` to send a
  /// value for this dimension.
  /// {@endtemplate}
  @protected
  Map<String, String>? dimensions;

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
      pvId: pvId,
      path: path,
      campaign: campaign,
      dimensions: dimensions,
    );
  }
}
