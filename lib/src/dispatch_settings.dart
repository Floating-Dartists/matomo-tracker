bool _whereNotOlderThanADay(Map<String, String> action) =>
    DispatchSettings.whereNotOlderThan(
      const Duration(
        hours: 23,
        minutes: 59,
        seconds: 59,
      ),
    )(action);

bool _notOlderThan(
  Map<String, String> action,
  DateTime now,
  Duration duration,
) {
  if (action['cdt'] case final date?) {
    return now.difference(DateTime.parse(date)) <= duration;
  }
  return false;
}

bool _takeAll(Map<String, String> action) => true;

bool _dropAll(Map<String, String> action) => false;

/// Used to filter out unwanted actions of the last session if using
/// [DispatchSettings.persistent].
///
/// Will invoked with the serialized `action` and should return `true` if the
/// action is still valid, or `false` if the action should be dropped.
///
/// Filters can be chained using [DispatchSettings.chain].
///
/// Some build in filters are [DispatchSettings.takeAll],
/// [DispatchSettings.dropAll], [DispatchSettings.whereUserId],
/// [DispatchSettings.whereNotOlderThan] and
/// [DispatchSettings.whereNotOlderThanADay].
typedef PersistenceFilter = bool Function(Map<String, String> action);

/// Controls the behaviour of dispatching actions to Matomo.
class DispatchSettings {
  /// Uses a persistent dispatch queue.
  ///
  /// This means that if the app terminates while there are still undispatched
  /// actions, those actions are dispatched on next app launch.
  ///
  /// The [onLoad] can be used to filter the stored actions and drop outdated
  /// ones. By default, only actions that are younger then a day are retained.
  /// See [PersistenceFilter] for some build in filters.
  const DispatchSettings.persistent({
    Duration dequeueInterval = defaultDequeueInterval,
    PersistenceFilter onLoad = whereNotOlderThanADay,
  }) : this._(
          dequeueInterval,
          true,
          onLoad,
        );

  /// Uses a non persistent dispatch queue.
  ///
  /// This means that if the app terminates while there are still undispatched
  /// actions, those actions are lost.
  const DispatchSettings.nonPersistent({
    Duration dequeueInterval = defaultDequeueInterval,
  }) : this._(
          dequeueInterval,
          false,
          null,
        );

  const DispatchSettings._(
    this.dequeueInterval,
    this.persistentQueue,
    this.onLoad,
  );

  /// The default duration between dispatching actions to the Matomo backend.
  static const Duration defaultDequeueInterval = Duration(
    seconds: 10,
  );

  /// Takes all actions.
  static const PersistenceFilter takeAll = _takeAll;

  /// Drops all actions.
  static const PersistenceFilter dropAll = _dropAll;

  /// Only takes actions where the userId is `uid`.
  static PersistenceFilter whereUserId(String uid) {
    return (Map<String, String> action) => action['uid'] == uid;
  }

  /// Only takes actions that are not older than `duration`.
  static PersistenceFilter whereNotOlderThan(Duration duration) =>
      (Map<String, String> action) => _notOlderThan(
            action,
            DateTime.now(),
            duration,
          );

  /// Shorthand for [whereNotOlderThan] with a duration of a day.
  static const PersistenceFilter whereNotOlderThanADay = _whereNotOlderThanADay;

  /// Combines multiple [PersistenceFilter]s.
  ///
  /// The returned filter is eager, which means that it will return `false`
  /// immediately and not check the reaming filters once a filter returned
  /// `false`.
  static PersistenceFilter chain(Iterable<PersistenceFilter> filters) {
    return filters.fold(takeAll, (previousValue, element) {
      return (Map<String, String> action) {
        if (previousValue(action)) {
          return element(action);
        } else {
          return false;
        }
      };
    });
  }

  /// How often to dispatch actions to the Matomo backend.
  final Duration dequeueInterval;

  /// Wheter to store actions persistently before dispatching.
  final bool persistentQueue;

  /// Used to determine which of the stored actions are still valid.
  ///
  /// Will not be `null` if [persistentQueue] is `true`, or `null` if `false`.
  final PersistenceFilter? onLoad;
}
