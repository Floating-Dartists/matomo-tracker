import 'package:http/http.dart' as http;
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:matomo_tracker/src/matomo_event.dart';
import 'package:mocktail/mocktail.dart';

class MockMatomoTracker extends Mock implements MatomoTracker {}

class MockTrackingOrderItem extends Mock implements TrackingOrderItem {}

class MockHttpClient extends Mock implements http.Client {}

class MockHttpResponse extends Mock implements http.Response {}

class MockMatomoEvent extends Mock implements MatomoEvent {}
