/// Validate a visitor ID.
///
/// A visitor ID must be a 16 characters hexadecimal string containing only
/// characters 01234567890abcdefABCDEF.
final validCidRegExp = RegExp(r'^[0-9a-fA-F]{16}$');
