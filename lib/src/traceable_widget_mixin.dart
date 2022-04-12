import 'package:flutter/material.dart';
import 'package:matomo/matomo.dart';

mixin TraceableStatelessMixin on StatelessWidget {
  late final String? traceName;
  late final String traceTitle;
  late final MatomoTracker tracker;

  @mustCallSuper
  void init({
    String? traceName,
    String traceTitle = 'WidgetCreated',
    MatomoTracker? tracker,
  }) {
    this.traceName = traceName;
    this.traceTitle = traceTitle;
    this.tracker = tracker ?? MatomoTracker.instance;
  }

  @override
  StatelessElement createElement() {
    tracker.trackScreenWithName(
      traceName ?? runtimeType.toString(),
      traceTitle,
    );
    return super.createElement();
  }
}

mixin TraceableStatefulMixin on StatefulWidget {
  late final String? traceName;
  late final String traceTitle;
  late final MatomoTracker tracker;

  @mustCallSuper
  void init({
    String? traceName,
    String traceTitle = 'WidgetCreated',
    MatomoTracker? tracker,
  }) {
    this.traceName = traceName;
    this.traceTitle = traceTitle;
    this.tracker = tracker ?? MatomoTracker.instance;
  }

  @override
  StatefulElement createElement() {
    tracker.trackScreenWithName(
      traceName ?? runtimeType.toString(),
      traceTitle,
    );
    return super.createElement();
  }
}

mixin TraceableInheritedMixin on InheritedWidget {
  late final String? traceName;
  late final String traceTitle;
  late final MatomoTracker tracker;

  @mustCallSuper
  void init({
    String? traceName,
    String traceTitle = 'WidgetCreated',
    MatomoTracker? tracker,
  }) {
    this.traceName = traceName;
    this.traceTitle = traceTitle;
    this.tracker = tracker ?? MatomoTracker.instance;
  }

  @override
  InheritedElement createElement() {
    tracker.trackScreenWithName(
      traceName ?? runtimeType.toString(),
      traceTitle,
    );
    return super.createElement();
  }
}
