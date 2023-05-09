import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

import '../ressources/mock/data.dart';

void main() {
  test('it should be able to create Visitor', () {
    final visitor = Visitor(
      id: visitorId,
      cid: cid,
      userId: userId,
    );

    expect(visitor.id, visitorId);
    expect(visitor.cid, cid);
    expect(visitor.userId, userId);
  });

  test('it should throw if cid is not 16 characters', () {
    Visitor getVisitorWithWrongCid() {
      return Visitor(
        id: visitorId,
        cid: wrongCid,
        userId: userId,
      );
    }

    expect(getVisitorWithWrongCid, throwsArgumentError);
  });

  test('it should throw if userId is null or empty', () {
    Visitor getVisitorWithNullUserId() {
      return Visitor(
        id: visitorId,
        cid: wrongCid,
      );
    }

    Visitor getVisitorWithEmptyUserId() {
      return Visitor(
        id: visitorId,
        cid: wrongCid,
        userId: '',
      );
    }

    expect(getVisitorWithNullUserId, throwsArgumentError);
    expect(getVisitorWithEmptyUserId, throwsArgumentError);
  });

  test('it should throw if cid contains invalid characters', () {
    Visitor getVisitorWithWrongCid() {
      return Visitor(
        id: visitorId,
        cid: wrongCharacterCid,
        userId: userId,
      );
    }

    expect(getVisitorWithWrongCid, throwsArgumentError);
  });
}
