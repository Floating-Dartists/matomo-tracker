import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

import '../ressources/mock/data.dart';

void main() {
  test('it should be able to create Visitor', () {
    final visitor = Visitor(
      id: visitorId,
      userId: userId,
    );

    expect(visitor.id, visitorId);
    expect(visitor.userId, userId);
  });

  test('it should throw if userId is null or empty', () {
    Visitor getVisitorWithNullUserId() {
      return Visitor(
        id: visitorId,
      );
    }

    Visitor getVisitorWithEmptyUserId() {
      return Visitor(
        id: visitorId,
        userId: '',
      );
    }

    expect(getVisitorWithNullUserId, throwsArgumentError);
    expect(getVisitorWithEmptyUserId, throwsArgumentError);
  });
}
