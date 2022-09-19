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

If you are in a `StatelessWidget` you can use the `TraceableWidget` widget:

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return TraceableWidget(
      traceName: 'Created HomePage', // optional
      traceTitle: title,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
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

## Using Dimensions

If you want to track Visit or Action dimensions you can either use the `trackDimensions` (if 
it's a Visit level dimension) or provide data in the optional dimensions param of `trackEvent`
(if it's an Action level dimension):

```dart
MatomoTracker.instance.trackDimensions({
  'dimension1': '0.0.1'
});
```

```dart
MatomoTracker.instance.trackEvent(
    name: 'eventName',
    action: 'eventAction',
    eventValue: 18,
    dimensions: {'dimension2':'guest-user'}
);
```

You can similarly track dimensions on Screen views with:

```dart
MatomoTracker.instance.trackScreenWithName(
      widgetName: "Settings",
      eventName: "screen_view",
      dimensions: {'dimension1': '0.0.1'}
    );
```

## Contributors

<!-- readme: contributors -start -->
<table>
<tr>
    <td align="center">
        <a href="https://github.com/TesteurManiak">
            <img src="https://avatars.githubusercontent.com/u/14369698?v=4" width="100;" alt="TesteurManiak"/>
            <br />
            <sub><b>Guillaume Roux</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/poitch">
            <img src="https://avatars.githubusercontent.com/u/80989?v=4" width="100;" alt="poitch"/>
            <br />
            <sub><b>Jêrôme Poichet</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/M123-dev">
            <img src="https://avatars.githubusercontent.com/u/39344769?v=4" width="100;" alt="M123-dev"/>
            <br />
            <sub><b>Marvin Möltgen</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/krillefear">
            <img src="https://avatars.githubusercontent.com/u/24619905?v=4" width="100;" alt="krillefear"/>
            <br />
            <sub><b>Krille Fear</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/KawachenCofinpro">
            <img src="https://avatars.githubusercontent.com/u/56601057?v=4" width="100;" alt="KawachenCofinpro"/>
            <br />
            <sub><b>Null</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/stefan01">
            <img src="https://avatars.githubusercontent.com/u/1234184?v=4" width="100;" alt="stefan01"/>
            <br />
            <sub><b>Null</b></sub>
        </a>
    </td></tr>
<tr>
    <td align="center">
        <a href="https://github.com/MeixDev">
            <img src="https://avatars.githubusercontent.com/u/14351291?v=4" width="100;" alt="MeixDev"/>
            <br />
            <sub><b>Meï</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/petcupaula">
            <img src="https://avatars.githubusercontent.com/u/12584735?v=4" width="100;" alt="petcupaula"/>
            <br />
            <sub><b>Paula Petcu</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/lsaudon">
            <img src="https://avatars.githubusercontent.com/u/25029876?v=4" width="100;" alt="lsaudon"/>
            <br />
            <sub><b>Lsaudon</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/Bendix20">
            <img src="https://avatars.githubusercontent.com/u/52244034?v=4" width="100;" alt="Bendix20"/>
            <br />
            <sub><b>Null</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/lukaslihotzki">
            <img src="https://avatars.githubusercontent.com/u/10326063?v=4" width="100;" alt="lukaslihotzki"/>
            <br />
            <sub><b>Lukas Lihotzki</b></sub>
        </a>
    </td>
    <td align="center">
        <a href="https://github.com/svprdga">
            <img src="https://avatars.githubusercontent.com/u/43069276?v=4" width="100;" alt="svprdga"/>
            <br />
            <sub><b>David Serrano Canales</b></sub>
        </a>
    </td></tr>
</table>
<!-- readme: contributors -end -->
