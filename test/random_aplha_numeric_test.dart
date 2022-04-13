import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/utils/random_alpha_numeric.dart';

void main() {
  test('test randomAlphaNumeric returns string with correct length', () {
    const length = 64;
    final randomString = randomAlphaNumeric(length);
    expect(randomString.length, length);
  });

  test('test randomAlphaNumeric returns string with allowed characters', () {
    const length = 42;
    final randomString = randomAlphaNumeric(length);

    final exp = RegExp("[0-9a-zA-z]{$length}");
    expect(true, exp.hasMatch(randomString));
  });
}
