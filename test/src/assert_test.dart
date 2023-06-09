import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/assert.dart';

void main() {
  group('assertStringIsFilled', () {
    test('should not do anything if string is null', () {
      expect(
        () => assertStringIsFilled(value: null, name: 'name'),
        returnsNormally,
      );
    });

    test('should not do anything if string is filled', () {
      expect(
        () => assertStringIsFilled(value: 'value', name: 'name'),
        returnsNormally,
      );
    });

    test('should throw if string is empty', () {
      expect(
        () => assertStringIsFilled(value: '', name: 'name'),
        throwsArgumentError,
      );
    });

    test('should throw if string contains only whitespace', () {
      expect(
        () => assertStringIsFilled(value: ' ', name: 'name'),
        throwsArgumentError,
      );
    });
  });

  group('assertDurationNotNegative', () {
    test('should not do anything if duration is null', () {
      expect(
        () => assertDurationNotNegative(value: null, name: 'name'),
        returnsNormally,
      );
    });

    test('should not do anything if duration is positive', () {
      expect(
        () => assertDurationNotNegative(
          value: const Duration(
            seconds: 1,
          ),
          name: 'name',
        ),
        returnsNormally,
      );
    });

    test('should not do anything if duration is zero', () {
      expect(
        () => assertDurationNotNegative(
          value: Duration.zero,
          name: 'name',
        ),
        returnsNormally,
      );
    });

    test('should throw if duration is negative', () {
      expect(
        () => assertDurationNotNegative(
          value: const Duration(
            seconds: -1,
          ),
          name: 'name',
        ),
        throwsArgumentError,
      );
    });
  });
}
