extension StringExtensions on String {
  /// If the string is not already prefixed with a slash, prefix it with one.
  String prefixWithSlash() {
    if (startsWith('/')) return this;
    return '/$this';
  }
}
