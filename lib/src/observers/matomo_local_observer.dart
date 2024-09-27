import 'package:flutter/widgets.dart';

/// {@macro matomo_local_observer}
@Deprecated(
  'Use matomoLocalObserver instead. '
  'This feature was deprecated in v6.0.0-dev.1 and will be removed in the next major version.',
)
final matomoObserver = matomoLocalObserver;

/// {@template matomo_local_observer}
/// A [RouteObserver] that will track navigation events in Matomo from a widget
/// that uses `TraceableWidgetMixin`.
/// {@endtemplate}
///
/// ### Example
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [
///     matomoLocalObserver,
///   ],
/// );
final matomoLocalObserver = RouteObserver<ModalRoute<void>>();
