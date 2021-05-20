import 'dart:math';

const _numericStart = 48;
const _numericEnd = 57;
const _lowerAlphaStart = 97;
const _lowerAlphaEnd = 122;
const _upperAlphaStart = 65;
const _upperAlphaEnd = 90;

Random _random = Random();

/// Generates a random string of [length] with alpha-numeric characters.
String randomAlphaNumeric(int length) {
  final alphaLength = _random.nextInt(length);

  final lowerCaseLength = alphaLength == 0 ? 0 : _random.nextInt(alphaLength);
  final upperCaseLength = alphaLength - lowerCaseLength;

  final lowerAlphaCharCodes =
      _generateRandomInts(lowerCaseLength, _lowerAlphaStart, _lowerAlphaEnd);
  final upperAlphaCharCodes =
      _generateRandomInts(upperCaseLength, _upperAlphaStart, _upperAlphaEnd);

  final alphaCharCodes = _randomMerge(lowerAlphaCharCodes, upperAlphaCharCodes);

  final numericLength = length - alphaLength;

  final numericCharCodes =
      _generateRandomInts(numericLength, _numericStart, _numericEnd);

  return String.fromCharCodes(_randomMerge(alphaCharCodes, numericCharCodes));
}

List<int> _generateRandomInts(int length, int lowerBound, int upperBound) {
  return List.generate(
      length, (_) => _random.nextInt(upperBound - lowerBound) + lowerBound);
}

/// Merge [a] with [b] and shuffle.
List<int> _randomMerge(List<int> a, List<int> b) {
  return List<int>.from(a)
    ..addAll(b)
    ..shuffle();
}
