import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/campaign.dart';

import '../ressources/mock/data.dart';

void main() {
  group('Campaign', () {
    test('should create a valid Campaign', () {
      final campaign = Campaign(
        name: matomoCampaignName,
        keyword: matomoCampaignKeyword,
        source: matomoCampaignSource,
        medium: matomoCampaignMedium,
        content: matomoCampaignContent,
        id: matomoCampaignId,
        group: matomoCampaignGroup,
        placement: matomoCampaignPlacement,
      );

      expect(campaign.name, matomoCampaignName);
      expect(campaign.keyword, matomoCampaignKeyword);
      expect(campaign.source, matomoCampaignSource);
      expect(campaign.medium, matomoCampaignMedium);
      expect(campaign.content, matomoCampaignContent);
      expect(campaign.id, matomoCampaignId);
      expect(campaign.group, matomoCampaignGroup);
      expect(campaign.placement, matomoCampaignPlacement);
    });

    test(
      'should throw an ArgumentError if name is empty or contains only whitespace',
      () {
        Campaign campaignWithEmptyName() {
          return Campaign(
            name: '',
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        Campaign campaignWithEmptyNameAndWhitespace() {
          return Campaign(
            name: ' ',
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        expect(campaignWithEmptyName, throwsArgumentError);
        expect(campaignWithEmptyNameAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if keyword is empty or contains only whitespace',
      () {
        Campaign campaignWithEmptyKeyword() {
          return Campaign(
            name: matomoCampaignName,
            keyword: '',
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        Campaign campaignWithEmptyKeywordAndWhitespace() {
          return Campaign(
            name: matomoCampaignName,
            keyword: ' ',
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        expect(campaignWithEmptyKeyword, throwsArgumentError);
        expect(campaignWithEmptyKeywordAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if source is empty or contains only whitespace',
      () {
        Campaign campaignWithEmptySource() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: '',
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        Campaign campaignWithEmptySourceAndWhitespace() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: ' ',
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        expect(campaignWithEmptySource, throwsArgumentError);
        expect(campaignWithEmptySourceAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if medium is empty or contains only whitespace',
      () {
        Campaign campaignWithEmptyMedium() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: '',
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        Campaign campaignWithEmptyMediumAndWhitespace() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: ' ',
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        expect(campaignWithEmptyMedium, throwsArgumentError);
        expect(campaignWithEmptyMediumAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if content is empty or contains only whitespace',
      () {
        Campaign campaignWithEmptyContent() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: '',
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        Campaign campaignWithEmptyContentAndWhitespace() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: ' ',
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        expect(campaignWithEmptyContent, throwsArgumentError);
        expect(campaignWithEmptyContentAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if id is empty or contains only whitespace',
      () {
        Campaign campaignWithEmptyId() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: '',
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        Campaign campaignWithEmptyIdAndWhitespace() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: ' ',
            group: matomoCampaignGroup,
            placement: matomoCampaignPlacement,
          );
        }

        expect(campaignWithEmptyId, throwsArgumentError);
        expect(campaignWithEmptyIdAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if group is empty or contains only whitespace',
      () {
        Campaign campaignWithEmptyGroup() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: '',
            placement: matomoCampaignPlacement,
          );
        }

        Campaign campaignWithEmptyGroupAndWhitespace() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: ' ',
            placement: matomoCampaignPlacement,
          );
        }

        expect(campaignWithEmptyGroup, throwsArgumentError);
        expect(campaignWithEmptyGroupAndWhitespace, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if placement is empty or contains only whitespace',
      () {
        Campaign campaignWithEmptyPlacement() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: '',
          );
        }

        Campaign campaignWithEmptyPlacementAndWhitespace() {
          return Campaign(
            name: matomoCampaignName,
            keyword: matomoCampaignKeyword,
            source: matomoCampaignSource,
            medium: matomoCampaignMedium,
            content: matomoCampaignContent,
            id: matomoCampaignId,
            group: matomoCampaignGroup,
            placement: ' ',
          );
        }

        expect(campaignWithEmptyPlacement, throwsArgumentError);
        expect(campaignWithEmptyPlacementAndWhitespace, throwsArgumentError);
      },
    );

    group('toMap', () {
      test('should return all non null properties inside the map', () {
        final map = Campaign(
          name: matomoCampaignName,
        ).toMap();

        final mapFull = Campaign(
          name: matomoCampaignName,
          keyword: matomoCampaignKeyword,
          source: matomoCampaignSource,
          medium: matomoCampaignMedium,
          content: matomoCampaignContent,
          id: matomoCampaignId,
          group: matomoCampaignGroup,
          placement: matomoCampaignPlacement,
        ).toMap();

        expect(mapEquals(map, wantedCampaignMap), isTrue);
        expect(mapEquals(mapFull, wantedCampaignMapFull), isTrue);
      });
    });
  });
}
