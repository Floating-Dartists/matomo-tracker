import 'package:flutter/material.dart';
import 'package:matomo_tracker/src/traceable_widget_mixin.dart';

class TestableApp extends StatelessWidget {
  const TestableApp({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
      navigatorObservers: [matomoObserver],
    );
  }
}
