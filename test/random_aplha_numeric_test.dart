import 'package:flutter_test/flutter_test.dart';
import 'package:matomo/random_alpha_numeric.dart';

void main() {
  test('test randomAlphaNumeric returns string with correct length', () {
    final randomString = randomAlphaNumeric(10);
    expect(randomString.length, 10);
  });

  test('test randomAlphaNumeric return string with allowed characters', () {
    final randomString = randomAlphaNumeric(10);

    final RegExp exp = RegExp(r"[0-9a-zA-z]{10}");
    expect(true, exp.hasMatch(randomString));
  });
}
