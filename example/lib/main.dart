import 'package:flutter/material.dart';
import 'package:matomo/matomo.dart';
import 'package:logging/logging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
    Logger.root.level = Level.FINEST;
    Logger.root.onRecord.listen((LogRecord rec) {
      print(
          '[${rec.time}][${rec.level.name}][${rec.loggerName}] ${rec.message}');
    });

    MatomoTracker.instance.initialize(
      siteId: 1,
      url: 'https://analytics.example.com/piwik.php',
    );
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matomo Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Matomo Example'),
    );
  }
}

class MyHomePage extends StatefulWidget with TraceableStatefulMixin {
  MyHomePage({Key key, this.title}) : super(key: key) {
    init(traceTitle: title);
  }

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    MatomoTracker.instance.trackEvent('IncrementCounter', 'Click');
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
