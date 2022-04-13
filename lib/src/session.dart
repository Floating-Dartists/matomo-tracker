class Session {
  /// Date of the visitor's first visit.
  final DateTime firstVisit;

  /// Date of the visitor's previous visit.
  final DateTime lastVisit;

  /// The current count of visits for this visitor.
  final int visitCount;

  Session({
    required this.firstVisit,
    required this.lastVisit,
    required this.visitCount,
  });
}
