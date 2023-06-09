import 'package:matomo_tracker/src/assert.dart';

/// Describes a content.
///
/// To track a content, first track [MatomoTracker.trackContentImpression], then,
/// if the user interacts with it, track [MatomoTracker.trackContentInteraction].
///
/// Read more about [Content Tracking](https://matomo.org/guide/reports/content-tracking/).
class Content {
  /// Describes a block of content.
  ///
  /// Note: Strings filled with whitespace will be considered as (invalid) empty
  /// values.
  factory Content({
    required String name,
    String? piece,
    String? target,
  }) {
    assertStringIsFilled(value: name, name: 'name');
    assertStringIsFilled(value: piece, name: 'piece');
    assertStringIsFilled(value: target, name: 'target');

    return Content._(
      name: name,
      piece: piece,
      target: target,
    );
  }

  const Content._({
    required this.name,
    this.piece,
    this.target,
  });

  /// The name of the content.
  ///
  /// For instance 'Ad Foo Bar'.
  ///
  /// Corresponds with `c_n`.
  final String name;

  /// The actual content piece.
  ///
  /// For instance the path to an image, video, audio, any text.
  ///
  /// Corresponds with `c_p`.
  final String? piece;

  /// The target of the content.
  ///
  /// For instance the URL of a landing page.
  ///
  /// Corresponds with `c_t`.
  final String? target;

  Map<String, String> toMap() {
    final cN = name;
    final cP = piece;
    final cT = target;

    return {
      'c_n': cN,
      if (cP != null) 'c_p': cP,
      if (cT != null) 'c_t': cT,
    };
  }
}
