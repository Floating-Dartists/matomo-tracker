class Visitor {
  /// The unique visitor ID, must be a 16 characters hexadecimal string.
  ///
  /// Every unique visitor must be assigned a different ID and this ID must not
  /// change after it is assigned. If this value is not set Matomo will still
  /// track visits, but the unique visitors metric might be less accurate.
  final String? id;

  final String? forcedId;
  final String? userId;

  Visitor({
    this.id,
    this.forcedId,
    this.userId,
  }) : assert(id == null || id.length == 16);
}
