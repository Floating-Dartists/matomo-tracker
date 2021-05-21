import 'package:flutter_test/flutter_test.dart';
import 'package:matomo/random_alpha_numeric.dart';

void main() {
  test('test randomAlphaNumeric returns string with correct length', () {
    final length = 64;
    final randomString = randomAlphaNumeric(length);
    expect(randomString.length, length);
  });

  test('test randomAlphaNumeric returns string with allowed characters', () {
    final length = 42;
    final randomString = randomAlphaNumeric(length);

    final RegExp exp = RegExp(r"[0-9a-zA-z]{"+length.toString()+"}");
    expect(true, exp.hasMatch(randomString));
  });
}
