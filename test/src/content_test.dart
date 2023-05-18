import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/content.dart';

import '../ressources/mock/data.dart';

void main() {
  group('Content', () {
    test('should create a valid Content', () {
      final content = Content(
        name: matomoContentName,
        piece: matomoContentPiece,
        target: matomoContentTarget,
      );

      expect(content.name, matomoContentName);
      expect(content.piece, matomoContentPiece);
      expect(content.target, matomoContentTarget);
    });

    test(
      'should throw an ArgumentError if name is empty or contains only whitespace',
      () {
        Content contentWithEmptyName() {
          return Content(
            name: '',
          );
        }

        Content contentWithEmptyNameAndWhitespace() {
          return Content(
            name: ' ',
          );
        }

        expect(contentWithEmptyName, throwsArgumentError);
        expect(contentWithEmptyNameAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if piece is empty or contains only whitespace',
      () {
        Content contentWithEmptyPiece() {
          return Content(
            name: matomoContentName,
            piece: '',
          );
        }

        Content contentWithEmptyPieceAndWhitespace() {
          return Content(
            name: matomoContentName,
            piece: ' ',
          );
        }

        expect(contentWithEmptyPiece, throwsArgumentError);
        expect(contentWithEmptyPieceAndWhitespace, throwsArgumentError);
      },
    );

    test(
        'should throw an ArgumentError if target is empty or contains only whitespace',
        () {
      Content contentWithEmptyTarget() {
        return Content(
          name: matomoContentName,
          target: '',
        );
      }

      Content contentWithEmptyTargetAndWhitespace() {
        return Content(
          name: matomoContentName,
          target: ' ',
        );
      }

      expect(contentWithEmptyTarget, throwsArgumentError);
      expect(contentWithEmptyTargetAndWhitespace, throwsArgumentError);
    });

    group('toMap', () {
      test('should return all non null properties inside the map', () {
        final map = Content(
          name: matomoContentName,
        ).toMap();

        final mapFull = Content(
                name: matomoContentName,
                piece: matomoContentPiece,
                target: matomoContentTarget)
            .toMap();

        expect(mapEquals(map, wantedContentMap), isTrue);
        expect(mapEquals(mapFull, wantedContentMapFull), isTrue);
      });
    });
  });
}
