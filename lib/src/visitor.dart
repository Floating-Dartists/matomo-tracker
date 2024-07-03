class Visitor {
  const Visitor({
    this.id,
    this.uid,
  }) : assert(
          uid == null || uid.length != 0,
          'uid must not be empty',
        );

  /// The unique visitor ID, must be a 16 characters hexadecimal string.
  ///
  /// Corresponds with `_id`.
  ///
  /// Every unique visitor must be assigned a different ID and this ID must not
  /// change after it is assigned. If this value is not set Matomo will still
  /// track visits, but the unique visitors metric might be less accurate.
  ///
  /// Think of this as a device ID; in case of website tracking (where Matomo
  /// originates), this would be the cookie identifying the browser and not
  /// necessarily a user (since a single browser might be used by multiple
  /// users).
  final String? id;

  /// The [User ID](https://matomo.org/guide/reports/user-ids/) is any non-empty
  /// unique string identifying the user (such as an email address or an
  /// username).
  ///
  /// Corresponds with `uid`.
  final String? uid;
}
