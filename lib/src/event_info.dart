/// Used to add context to the event send.
///
/// - `category`: The event category. Must not be empty. (eg. Videos, Music,
/// Games...). This corresponds with `e_c`.
///
/// - `action`: The event action. Must not be empty. (eg. Play, Pause, Duration,
/// Add Playlist, Downloaded, Clicked...). This corresponds with `e_a`.
///
/// - `name`: The event name. (eg. a Movie name, or Song name, or File name...).
/// This corresponds with `e_n`.
///
/// - `value`: The event value. This corresponds with `e_v`.
///
/// Note: Strings filled with whitespace will be considered as (invalid) empty
/// values.
class EventInfo {
  factory EventInfo({
    required String category,
    required String action,
    String? name,
    num? value,
  }) {
    if (category.trim().isEmpty) {
      throw ArgumentError.value(
        category,
        'category',
        'Must not be empty or whitespace only.',
      );
    }

    if (action.trim().isEmpty) {
      throw ArgumentError.value(
        action,
        'action',
        'Must not be empty or whitespace only.',
      );
    }

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Must not be empty or whitespace only.',
      );
    }

    return EventInfo._(
      category: category,
      action: action,
      name: name,
      value: value,
    );
  }

  const EventInfo._({
    required this.category,
    required this.action,
    this.name,
    this.value,
  });

  final String category;
  final String action;
  final String? name;
  final num? value;

  Map<String, String> toMap() {
    final localName = name;

    return <String, String>{
      'e_c': category,
      'e_a': action,
      if (localName != null) 'e_n': localName,
      if (value != null) 'e_v': '$value',
    };
  }
}
