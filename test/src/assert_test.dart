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

    test('should not do anything is string is filled', () {
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
}
