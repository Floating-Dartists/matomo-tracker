import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/session.dart';

import '../mock/data.dart';

void main() {
  test('it should be able to create Session', () async {
    final session = Session(
      firstVisit: sessionFirstVisiste,
      lastVisit: sessionLastVisiste,
      visitCount: sessionVisitCount,
    );

    expect(session.firstVisit, sessionFirstVisiste);
    expect(session.lastVisit, sessionLastVisiste);
    expect(session.visitCount, sessionVisitCount);
  });
}
