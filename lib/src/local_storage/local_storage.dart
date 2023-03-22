abstract class LocalStorage {
  Future<String?> getVisitorId();
  Future<void> setVisitorId(String visitorId);
  Future<DateTime?> getFirstVisit();
  Future<void> setFirstVisit(DateTime firstVisit);
  Future<int> getVisitCount();
  Future<void> setVisitCount(int visitCount);
  Future<bool> getOptOut();
  Future<void> setOptOut({required bool optOut});
  Future<void> clear();
}
