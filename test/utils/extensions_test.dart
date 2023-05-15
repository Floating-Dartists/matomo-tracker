import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/utils/extensions.dart';

void main() {
  group('StringExtensions', () {
    group('prefixWithSlash', () {
      test('should return the same string', () {
        const String testString = '/test';
        expect(testString.prefixWithSlash(), testString);
      });

      test('should return the string with a slash prefix', () {
        const String testString = 'test';
        expect(testString.prefixWithSlash(), '/$testString');
      });
    });
  });
}
