# matomo

Forked from the package [matomo](https://pub.dev/packages/matomo) by [poitch](https://github.com/poitch).

A fully cross-platform wrap of the Matomo tracking client for Flutter, using the Matomo API.

## Getting Started

As early as possible in your application, you need to configure the Matomo Tracker to pass the URL endpoint of your instance and your Site ID.

```dart
    await MatomoTracker.instance.initialize(
        siteId: siteId,
        url: 'https://example.com/piwik.php',
    );
```

If you need to use your own Visitor ID, you can pass it at the initialization of MatomoTracker as is:

```dart
    await MatomoTracker.instance.initialize(
        siteId: siteId,
        url: 'https://example.com/piwik.php',
        visitorId: 'customer_1',
    );
```

To track views simply add `TraceableStatelessMixin`, `TraceableStatefulMixin` or `TraceableInheritedMixin` to your widget and **call the `init()` method in the constructor**.

```dart
class MyWidget extends StatelessWidget with TraceableStatelessMixin {
    MyWidget({Key? key, this.title}) : super(key: key) {
        init(traceTitle: title);
    }
    
    final String title;
    
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(
                child: ElevatedButton(
                    onPressed: () {
                        MatomoTracker.instance.trackEvent(
                            name: 'PressedButton',
                            action: 'Click',
                        );
                    },
                    child: Text('Track Event'),
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
    eventValue: 'eventValue',
);
```

## Opting Out

If you want to offer a way for the user to opt out of analytics, you can use the `setOptOut()` call.

```dart
MatomoTracker.instance.setOptOut(optout: true);
```