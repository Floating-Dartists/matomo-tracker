# Matomo Tracker

<p align="center">
  <a href="https://github.com/Floating-Dartists" target="_blank">
    <img src="https://raw.githubusercontent.com/Floating-Dartists/fd_template/main/assets/Transparent-light.png" alt="Floating Dartists" width="600">
  </a>
</p>

[![Pub Version](https://img.shields.io/pub/v/matomo_tracker)](https://pub.dev/packages/matomo_tracker)
[![Matomo Integrations](https://img.shields.io/badge/featured%20on-Matomo-blue)](https://matomo.org/integrate/)
[![GitHub license](https://img.shields.io/github/license/Floating-Dartists/matomo-tracker)](https://github.com/Floating-Dartists/matomo-tracker/blob/main/LICENSE)

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
    visitorId: '2589631479517535',
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
    eventValue: 18,
);
```

## Using userId

If your application uses authentication and you wish to have your visitors including their specific identity to Matomo, you can use the Visitor property userId with any unique identifier from your back-end, by calling the setVisitorUserId() method. Here's an example on how to do it with Firebase:

```dart
  String userId = auth.currentUser?.email ?? auth.currentUser!.uid;
  MatomoTracker.instance.setVisitorUserId(userId);
```

## Opting Out

If you want to offer a way for the user to opt out of analytics, you can use the `setOptOut()` call.

```dart
MatomoTracker.instance.setOptOut(optout: true);
```
