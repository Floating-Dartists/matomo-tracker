abstract interface class LocalStorage {
  Future<String?> getVisitorId();
  Future<void> setVisitorId(String visitorId);
  Future<bool> getOptOut();
  Future<void> setOptOut({required bool optOut});
  Future<void> storeActions(String serializedActions);
  Future<String?> loadActions();

  /// {@template local_storage.clear}
  /// Clear the following data from the local storage:
  ///
  /// - First visit
  /// - Number of visits
  /// - Visitor ID
  /// - Action Queue
  /// {@endtemplate}
  Future<void> clear();
}
