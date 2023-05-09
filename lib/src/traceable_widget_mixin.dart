import 'package:flutter/material.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:matomo_tracker/utils/random_alpha_numeric.dart';

/// Register a [MatomoTracker.trackScreenWithName] on this widget.
@optionalTypeArgs
mixin TraceableClientMixin<T extends StatefulWidget> on State<T> {
  /// {@template traceableClientMixin.actionName}
  /// Equivalent to the page name. (e.g. `'HomePage'`).
  /// {@endtemplate}
  @protected
  String get actionName => 'Created widget ${widget.toStringShort()}';

  /// {@template traceableClientMixin.pvId}
  /// A 6 character unique ID.
  ///
  /// The default implementation will generate one on widget creation.
  /// {@endtemplate}
  @protected
  String get pvId => _pvId;
  String _pvId = randomAlphaNumeric(6);

  /// {@template traceableClientMixin.path}
  /// Path to the widget. (e.g. `'/home'`).
  ///
  /// This will be combined with [MatomoTracker.contentBase]. The combination
  /// corresponds with `url`.
  /// {@endtemplate}
  @protected
  String? path;

  /// {@template traceableClientMixin.dimensions}
  /// A Custom Dimension value for a specific Custom Dimension ID.
  ///
  /// If Custom Dimension ID is 2 use `dimension2=dimensionValue` to send a
  /// value for this dimension.
  /// 
  /// For additional remarks see [MatomoTracker.trackDimensions].
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
      dimensions: dimensions,
    );
  }

  /// Should be called if a [Navigator.pop]s back to this page.
  ///
  /// This will than trigger an action to tell Matomo that the
  /// app is back on this page.
  ///
  /// If you do not consider this a new page view in your apps logic,
  /// you should set [updatePvId] to `false` to tell the widget to keep
  /// the old [pvId]. If you overworte the [pvId] getter, this has no
  /// effect.
  @protected
  void onReentry({bool updatePvId = true}) {
    if (updatePvId) {
      _pvId = randomAlphaNumeric(6);
    }
    _startTracking();
  }
}
