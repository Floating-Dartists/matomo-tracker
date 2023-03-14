import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/exceptions.dart';

void main() {
  group('MatomoException', () {
    const exception = MatomoException(message: 'test');

    test('toString', () {
      expect(exception.toString(), 'MatomoException: test');
    });
  });

  group('UninitializedMatomoInstanceException', () {
    const exception = UninitializedMatomoInstanceException();

    test('toString', () {
      expect(
        exception.toString(),
        'MatomoException: MatomoTracker has not been initialized properly, call the method initialize() first.',
      );
    });
  });
}
