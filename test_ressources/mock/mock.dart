import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:matomo_tracker/src/matomo_event.dart';
import 'package:matomo_tracker/src/session.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMatomoTracker extends Mock implements MatomoTracker {}

class MockTrackingOrderItem extends Mock implements TrackingOrderItem {}

class MockHttpClient extends Mock implements http.Client {}

class MockHttpResponse extends Mock implements http.Response {}

class MockMatomoEvent extends Mock implements MatomoEvent {}

class MockVisitor extends Mock implements Visitor {}

class MockSession extends Mock implements Session {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockPackageInfo extends Mock implements PackageInfo {}

class MockBuildContext extends Mock implements BuildContext {}

// used to mock widgets
class MockWidget extends StatelessWidget {
  const MockWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

final mockMatomoTracker = MockMatomoTracker();
final mockTrackingOrderItem = MockTrackingOrderItem();
final mockHttpClient = MockHttpClient();
final mockMatomoEvent = MockMatomoEvent();
final mockHttpResponse = MockHttpResponse();
final mockVisitor = MockVisitor();
final mockSession = MockSession();
final mockSharedPreferences = MockSharedPreferences();
final mockPackageInfo = MockPackageInfo();
final mockBuildContext = MockBuildContext();
