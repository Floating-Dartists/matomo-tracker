import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

import '../ressources/mock/data.dart';

void main() {
  test('it should be able to create Visitor', () {
    const visitor = Visitor(
      id: visitorId,
      uid: uid,
    );

    expect(visitor.id, visitorId);
    expect(visitor.uid, uid);
  });

  test('it should throw if userId is empty', () {
    Visitor getVisitorWithEmptyUserId() {
      return Visitor(
        id: visitorId,
        uid: '',
      );
    }

    expect(getVisitorWithEmptyUserId, throwsAssertionError);
  });
}
