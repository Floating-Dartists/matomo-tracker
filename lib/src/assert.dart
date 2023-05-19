/// Method used to assert that a string is not empty or composed of whitespace
/// only.
///
/// If the passed [value] is null, it won't do anything.
void assertStringIsFilled({required String? value, required String name}) {
  if (value != null && value.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      name,
      'Must not be empty or whitespace only.',
    );
  }
}

/// Method used to assert that a duration is not negative.
///
/// If the passed [value] is null, it won't do anything.
void assertDurationNotNegative({required Duration? value, required String name}) {
  if (value != null && value.isNegative) {
    throw ArgumentError.value(
      value,
      name,
      'Must not be negative.',
    );
  }
}
