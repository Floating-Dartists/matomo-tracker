class Visitor {
  factory Visitor({
    String? id,
    String? userId,
  }) {
    if (userId != null && userId.isEmpty) {
      throw ArgumentError('Must not be empty', 'userId');
    }

    return Visitor._(
      id: id,
      userId: userId,
    );
  }

  Visitor._({
    this.id,
    this.userId,
  });

  /// The unique visitor ID, must be a 16 characters hexadecimal string.
  ///
  /// Every unique visitor must be assigned a different ID and this ID must not
  /// change after it is assigned. If this value is not set Matomo will still
  /// track visits, but the unique visitors metric might be less accurate.
  final String? id;

  /// User ID is any non-empty unique string identifying the user (such as an
  /// email address or an username).
  ///
  /// Corresponds with the `uid` parameter.
  final String? userId;
}
