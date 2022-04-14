<p align="center">
  <a href="https://github.com/Floating-Dartists">
    <img src="https://i.imgur.com/Gd0Mh6y.png" width="800">
  </a>
</p>

# matomo_tracker

[![Pub Version](https://img.shields.io/pub/v/matomo_tracker)](https://pub.dev/packages/matomo_tracker)

Forked from the package [matomo](https://pub.dev/packages/matomo) by [poitch](https://github.com/poitch).

A fully cross-platform wrap of the Matomo tracking client for Flutter, using the [Matomo Tracking API](https://developer.matomo.org/api-reference/tracking-api).

## Getting Started

As early as possible in your application, you need to configure the Matomo Tracker to pass the URL endpoint of your instance and your Site ID.

```dart
await MatomoTracker.instance.initialize(
    siteId: siteId,
    url: 'https://example.com/matomo.php',
);
```

If you need to use your own Visitor ID, you can pass it at the initialization of MatomoTracker as is:

```dart
await MatomoTracker.instance.initialize(
    siteId: siteId,
    url: 'https://example.com/matomo.php',
    visitorId: 'customer_1',
);
```

To track views simply add `TraceableClientMixin` on your `State`:

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TraceableClientMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Text('Hello World!'),
      ),
    );
  }

  @override
  String get traceName => 'Created HomePage'; // optional

  @override
  String get traceTitle => widget.title;
}
```

You can also optionally call directly `trackScreen` or `trackScreenWithName` to track a view.

For tracking goals and, events call `trackGoal` and `trackEvent` respectively.

A value can be passed for events:

```dart
MatomoTracker.instance.trackEvent(
    name: 'eventName',
    action: 'eventAction',
    eventValue: 'eventValue',
);
```

## Opting Out

If you want to offer a way for the user to opt out of analytics, you can use the `setOptOut()` call.

```dart
MatomoTracker.instance.setOptOut(optout: true);
```
