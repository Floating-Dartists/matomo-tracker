import 'package:matomo_tracker/utils/regexp.dart';

class Visitor {
  factory Visitor({
    String? id,
    String? cid,
    String? userId,
    // TODO: Remove forcedId in version 4.0.0
    @Deprecated('Use cid paramater instead') String? forcedId,
  }) {
    if (userId != null && userId.isEmpty) {
      throw ArgumentError('Must not be empty', 'userId');
    }

    final localCid = forcedId ?? cid;

    if (localCid != null && validCidRegExp.hasMatch(localCid) == false) {
      throw ArgumentError(
        'Must be a 16 characters hexadecimal string containing only characters 01234567890abcdefABCDEF',
        'cid',
      );
    }

    return Visitor._(
      id: id,
      cid: localCid,
      userId: userId,
    );
  }

  Visitor._({
    this.id,
    this.cid,
    this.userId,
  });

  /// The unique visitor ID, must be a 16 characters hexadecimal string.
  ///
  /// Every unique visitor must be assigned a different ID and this ID must not
  /// change after it is assigned. If this value is not set Matomo will still
  /// track visits, but the unique visitors metric might be less accurate.
  final String? id;

  /// {@template visitor.cid}
  /// Defines the visitor ID for this request.
  ///
  /// You must set this value to exactly a 16 character hexadecimal string
  /// (containing only characters 01234567890abcdefABCDEF).
  ///
  /// We recommended setting the User ID via [userId] rather than use this.
  /// {@endtemplate}
  final String? cid;

  /// User ID is any non-empty unique string identifying the user (such as an
  /// email address or an username).
  ///
  /// Corresponds with the `uid` parameter.
  final String? userId;

  // TODO: Remove forcedId in version 4.0.0
  @Deprecated('Use cid instead')
  String? get forcedId => cid;
}
