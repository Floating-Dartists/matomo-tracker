# matomo

A Dart Client for Matomo. This is completely written in Dart and works cross-platform.

## Getting Started

```
dependencies:
    matomo: ^0.0.3
```

As early as possible in your application you need to configure the Matomo Tracker to pass the URL endpoint of your instance and your Site ID.

```dart
    await MatomoTracker().initialize(
        siteId: siteId,
        url: 'https://example.com/piwik.php',
    );
```

If you need to use your own Visitor ID, you can pass it at the initialization of MatomoTracker as is:

```dart
    await MatomoTracker().initialize(
        siteId: siteId,
        url: 'https://example.com/piwik.php',
        visitorId: 'customer_1',
    );
```

To track views simply replace `StatelessWidget` by `TraceableStatelessWidget`, `StatefulWidget` by `TraceableStatefulWidget` and finally `InheritedWidget` by `TraceableInheritedWidget`.

You can also optionally call directly `trackScreen` or `trackScreenWithName` to track a view.

For tracking goals and events call `trackGoal` and `trackEvent` respectively.

## Opting Out

If you want to offer a way for the user to opt-out of analytics, you can use the ```setOptOut()``` call.

```dart
MatomoTracker().setOptOut(true);
```