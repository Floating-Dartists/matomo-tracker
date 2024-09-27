import 'package:flutter/widgets.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

/// {@template matomo_global_observer}
/// A [RouteObserver] that will track all the route navigation events in Matomo.
///
/// You can specify a custom [MatomoTracker] instance with the `tracker`
/// parameter. (defaults to [MatomoTracker.instance] if not provided)
///
/// ### Example
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [
///     MatomoGlobalObserver(),
///   ],
/// );
/// ```
/// {@endtemplate}
class MatomoGlobalObserver extends RouteObserver<PageRoute<dynamic>> {
  /// {@macro matomo_global_observer}
  MatomoGlobalObserver({
    MatomoTracker? tracker,
  }) : _tracker = tracker ?? MatomoTracker.instance;

  final MatomoTracker _tracker;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackPageView(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _trackPageView(previousRoute);
  }

  void _trackPageView(Route<dynamic>? route) {
    _tracker.trackPageViewWithName(
      actionName: route?.settings.name ?? 'unknown',
    );
  }
}
