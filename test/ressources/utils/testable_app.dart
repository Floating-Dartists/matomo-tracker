import 'package:flutter/material.dart';
import 'package:matomo_tracker/src/observers/matomo_local_observer.dart';

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
      navigatorObservers: [matomoLocalObserver],
    );
  }
}
