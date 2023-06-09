import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/event_info.dart';

import '../ressources/mock/data.dart';

void main() {
  group('EventInfo', () {
    test('should create a valid EventInfo', () {
      final eventInfo = EventInfo(
        category: matomoEventCategory,
        action: matomoActionName,
        name: matomoEventName,
        value: matomoEventValue,
      );

      expect(eventInfo.category, matomoEventCategory);
      expect(eventInfo.action, matomoActionName);
      expect(eventInfo.name, matomoEventName);
      expect(eventInfo.value, matomoEventValue);
    });

    test(
      'should throw an ArgumentError if category is empty or contains only whitespace',
      () {
        EventInfo eventWithEmptyCategory() {
          return EventInfo(
            category: '',
            action: matomoActionName,
          );
        }

        EventInfo eventWithEmptyCategoryAndWhitespace() {
          return EventInfo(
            category: ' ',
            action: matomoActionName,
          );
        }

        expect(eventWithEmptyCategory, throwsArgumentError);
        expect(eventWithEmptyCategoryAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if action is empty or contains only whitespace',
      () {
        EventInfo eventWithEmptyAction() {
          return EventInfo(
            category: matomoEventCategory,
            action: '',
          );
        }

        EventInfo eventWithEmptyActionAndWhitespace() {
          return EventInfo(
            category: matomoEventCategory,
            action: ' ',
          );
        }

        expect(eventWithEmptyAction, throwsArgumentError);
        expect(eventWithEmptyActionAndWhitespace, throwsArgumentError);
      },
    );

    test(
        'should throw an ArgumentError if name is empty or contains only whitespace',
        () {
      EventInfo eventWithEmptyName() {
        return EventInfo(
          category: matomoEventCategory,
          action: matomoActionName,
          name: '',
        );
      }

      EventInfo eventWithEmptyNameAndWhitespace() {
        return EventInfo(
          category: matomoEventCategory,
          action: matomoActionName,
          name: ' ',
        );
      }

      expect(eventWithEmptyName, throwsArgumentError);
      expect(eventWithEmptyNameAndWhitespace, throwsArgumentError);
    });

    group('toMap', () {
      test('should return all non null properties inside the map', () {
        final map = EventInfo(
          category: matomoEventCategory,
          action: matomoActionName,
        ).toMap();

        final mapFull = EventInfo(
          category: matomoEventCategory,
          action: matomoActionName,
          name: matomoEventName,
          value: matomoEventValue,
        ).toMap();

        expect(mapEquals(map, wantedEventMap), isTrue);
        expect(mapEquals(mapFull, wantedEventMapFull), isTrue);
      });
    });
  });
}
