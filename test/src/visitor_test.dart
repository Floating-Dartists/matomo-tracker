import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

import '../ressources/mock/data.dart';

void main() {
  test('it should be able to create Visitor', () async {
    final visitor = Visitor(
      id: visitorId,
      forcedId: forceId,
      userId: userId,
    );

    expect(visitor.id, visitorId);
    expect(visitor.forcedId, forceId);
    expect(visitor.userId, userId);
  });

  test('it should throw if forceId is not 16 characters', () async {
    Visitor getVisitorWithWrongForceId() {
      return Visitor(
        id: visitorId,
        forcedId: wrongForceId,
        userId: userId,
      );
    }

    expect(getVisitorWithWrongForceId, throwsAssertionError);
  });

  test('it should throw if userId is null or empty', () async {
    Visitor getVisitorWithNullUserId() {
      return Visitor(
        id: visitorId,
        forcedId: wrongForceId,
      );
    }

    Visitor getVisitorWithEmptyUserId() {
      return Visitor(
        id: visitorId,
        forcedId: wrongForceId,
        userId: '',
      );
    }

    expect(getVisitorWithNullUserId, throwsAssertionError);
    expect(getVisitorWithEmptyUserId, throwsAssertionError);
  });
}
