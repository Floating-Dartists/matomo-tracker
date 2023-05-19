import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/performance_info.dart';

import '../ressources/mock/data.dart';

void main() {
  group('PerformanceInfo', () {
    test('should create a valid PerformanceInfo', () {
      final performanceInfo = PerformanceInfo(
        networkTime: matomoPerformanceInfoNetworkTime,
        serverTime: matomoPerformanceInfoServerTime,
        transferTime: matomoPerformanceInfoTransferTime,
        domProcessingTime: matomoPerformanceInfoDomProcessingTime,
        domCompletionTime: matomoPerformanceInfoDomCompletionTime,
        onloadTime: matomoPerformanceInfoOnloadTime,
      );

      expect(performanceInfo.networkTime, matomoPerformanceInfoNetworkTime);
      expect(performanceInfo.serverTime, matomoPerformanceInfoServerTime);
      expect(performanceInfo.transferTime, matomoPerformanceInfoTransferTime);
      expect(
        performanceInfo.domProcessingTime,
        matomoPerformanceInfoDomProcessingTime,
      );
      expect(
        performanceInfo.domCompletionTime,
        matomoPerformanceInfoDomCompletionTime,
      );
      expect(performanceInfo.onloadTime, matomoPerformanceInfoOnloadTime);
    });

    test(
      'should throw an ArgumentError if networkTime is negative',
      () {
        PerformanceInfo performanceInfoWithNegativeNetworkTime() {
          return PerformanceInfo(
            networkTime: const Duration(
              seconds: -1,
            ),
          );
        }

        expect(performanceInfoWithNegativeNetworkTime, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if serverTime is negative',
      () {
        PerformanceInfo performanceInfoWithNegativeServerTime() {
          return PerformanceInfo(
            serverTime: const Duration(
              seconds: -1,
            ),
          );
        }

        expect(performanceInfoWithNegativeServerTime, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if transferTime is negative',
      () {
        PerformanceInfo performanceInfoWithNegativeTransferTime() {
          return PerformanceInfo(
            transferTime: const Duration(
              seconds: -1,
            ),
          );
        }

        expect(performanceInfoWithNegativeTransferTime, throwsArgumentError);
      },
    );

    test(
      'should throw an ArgumentError if domProcessingTime is negative',
      () {
        PerformanceInfo performanceInfoWithNegativeDomProcessingTime() {
          return PerformanceInfo(
            domProcessingTime: const Duration(
              seconds: -1,
            ),
          );
        }

        expect(
          performanceInfoWithNegativeDomProcessingTime,
          throwsArgumentError,
        );
      },
    );

    test(
      'should throw an ArgumentError if domCompletionTime is negative',
      () {
        PerformanceInfo performanceInfoWithNegativeDomCompletionTime() {
          return PerformanceInfo(
            domCompletionTime: const Duration(
              seconds: -1,
            ),
          );
        }

        expect(
          performanceInfoWithNegativeDomCompletionTime,
          throwsArgumentError,
        );
      },
    );

    test(
      'should throw an ArgumentError if onloadTime is negative',
      () {
        PerformanceInfo performanceInfoWithNegativeOnloadTime() {
          return PerformanceInfo(
            onloadTime: const Duration(
              seconds: -1,
            ),
          );
        }

        expect(performanceInfoWithNegativeOnloadTime, throwsArgumentError);
      },
    );

    group('toMap', () {
      test('should return all non null properties inside the map', () {
        final mapFull = PerformanceInfo(
          networkTime: matomoPerformanceInfoNetworkTime,
          serverTime: matomoPerformanceInfoServerTime,
          transferTime: matomoPerformanceInfoTransferTime,
          domProcessingTime: matomoPerformanceInfoDomProcessingTime,
          domCompletionTime: matomoPerformanceInfoDomCompletionTime,
          onloadTime: matomoPerformanceInfoOnloadTime,
        ).toMap();

        expect(mapEquals(mapFull, wantedPerformanceInfoMapFull), isTrue);
      });

      test('fields that are null should not be inside the map', () {
        final map = PerformanceInfo().toMap();

        expect(mapEquals(map, {}), isTrue);
      });

      test('zero durations should be omitted from the map', () {
        final mapWithoutZero = PerformanceInfo(
          networkTime: matomoPerformanceInfoNetworkTime,
          serverTime: Duration.zero,
          transferTime: Duration.zero,
          domProcessingTime: Duration.zero,
          domCompletionTime: Duration.zero,
          onloadTime: Duration.zero,
        ).toMap();

        expect(mapEquals(mapWithoutZero, wantedPerformanceMap), isTrue);
      });
    });
  });
}
