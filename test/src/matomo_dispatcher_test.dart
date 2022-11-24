import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/logger.dart';
import 'package:matomo_tracker/src/matomo_dispatcher.dart';
import 'package:mocktail/mocktail.dart';

import '../mock/data.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
    when(mockMatomoEvent.toMap).thenReturn({});
    when(() => mockMatomoEvent.tracker).thenReturn(mockMatomoTracker);
    when(() => mockMatomoTracker.userAgent).thenReturn(null);
    when(() => mockMatomoTracker.log).thenReturn(Logger());
  });

  test('it should be able to send MatomoEvent', () async {
    when(() => mockHttpClient.post(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => mockHttpResponse);
    when(() => mockHttpResponse.statusCode).thenReturn(200);

    final matomoDispatcher = MatomoDispatcher(
      matomoDispatcherBaseUrl,
      matomoDispatcherToken,
      httpClient: mockHttpClient,
    );

    await matomoDispatcher.send(mockMatomoEvent);

    verify(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
      ),
    ).called(1);
  });

  group('sendBatch', () {
    setUpAll(
      () {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => mockHttpResponse);
        when(() => mockHttpResponse.statusCode).thenReturn(200);
      },
    );

    test('it should be able to send MatomoEvent in batch', () async {
      final matomoDispatcher = MatomoDispatcher(
        matomoDispatcherBaseUrl,
        matomoDispatcherToken,
        httpClient: mockHttpClient,
      );

      await matomoDispatcher.sendBatch([mockMatomoEvent, mockMatomoEvent]);

      verify(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test(
        'it should send nothing in sendBatch if the list of MatomoEvent is empty',
        () async {
      final matomoDispatcher = MatomoDispatcher(
        matomoDispatcherBaseUrl,
        matomoDispatcherToken,
        httpClient: mockHttpClient,
      );

      await matomoDispatcher.sendBatch([]);

      verifyNever(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );
    });
  });

  test("it should add the tokenAuth to Uri if it's not null", () {
    final matomoDispatcher = MatomoDispatcher(
      matomoDispatcherBaseUrl,
      matomoDispatcherToken,
      httpClient: mockHttpClient,
    );

    final uri = matomoDispatcher.buildUriForEvent(mockMatomoEvent);

    expect(
      uri.queryParameters[MatomoDispatcher.tokenAuthUriKey],
      matomoDispatcherToken,
    );
  });
}
