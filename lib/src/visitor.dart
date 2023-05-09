class Visitor {
  Visitor({
    this.id,
    this.forcedId,
    this.userId,
  })  : assert(userId == null || userId.isNotEmpty, 'userId must not be empty'),
        assert(
          forcedId == null || forcedId.length == 16,
          'forcedId must be 16 characters',
        );

  /// The unique visitor ID, must be a 16 characters hexadecimal string.
  ///
  /// Every unique visitor must be assigned a different ID and this ID must not
  /// change after it is assigned. If this value is not set Matomo will still
  /// track visits, but the unique visitors metric might be less accurate.
  final String? id;

  /// Defines the visitor ID for this request.
  ///
  /// You must set this value to exactly a 16 character hexadecimal string
  /// (containing only characters 01234567890abcdefABCDEF).
  ///
  /// We recommended setting the User ID via [userId] rather than use this
  /// [forcedId].
  final String? forcedId;

  /// User ID is any non-empty unique string identifying the user (such as an
  /// email address or an username).
  /// 
  /// Corresponds with the `uid` parameter.
  final String? userId;
}
