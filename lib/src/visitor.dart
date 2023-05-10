class Visitor {
  factory Visitor({
    String? id,
    String? uid,
  }) {
    if (uid != null && uid.isEmpty) {
      throw ArgumentError('Must not be empty', 'uid');
    }

    return Visitor._(
      id: id,
      uid: uid,
    );
  }

  Visitor._({
    this.id,
    this.uid,
  });

  /// The unique visitor ID, must be a 16 characters hexadecimal string.
  ///
  /// Every unique visitor must be assigned a different ID and this ID must not
  /// change after it is assigned. If this value is not set Matomo will still
  /// track visits, but the unique visitors metric might be less accurate.
  final String? id;

  /// [User ID](https://matomo.org/guide/reports/user-ids/) is any non-empty
  /// unique string identifying the user (such as an email address or an
  /// username).
  final String? uid;
}
