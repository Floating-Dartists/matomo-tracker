import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/matomo_dispatcher.dart';
import 'package:mocktail/mocktail.dart';

import '../ressources/mock/data.dart';
import '../ressources/mock/mock.dart';

void main() {
  const headerKey = 'foo';
  const headerValue = 'bar';

  setUpAll(() {
    registerFallbackValue(Uri());
    when(() => mockMatomoAction.toMap(mockMatomoTracker)).thenReturn({});
    when(() => mockMatomoTracker.userAgent).thenReturn(null);
    when(() => mockMatomoTracker.log).thenReturn(mockLogger);
    when(() => mockMatomoTracker.customHeaders).thenReturn({});
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

    test('it should be able to send MatomoAction in batch', () async {
      final matomoDispatcher = MatomoDispatcher(
        baseUrl: matomoDispatcherBaseUrl,
        userAgent: matomoTrackerUserAgent,
        tokenAuth: matomoDispatcherToken,
        httpClient: mockHttpClient,
        log: mockLogger,
      );

      await matomoDispatcher.sendBatch(
        actions: [mockMatomoAction, mockMatomoAction]
            .map((action) => action.toMap(mockMatomoTracker))
            .toList(),
      );

      verify(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );
    });

    test('it should set user agent in http request', () async {
      final actions = [mockMatomoAction, mockMatomoAction];

      final matomoDispatcher = MatomoDispatcher(
        baseUrl: matomoDispatcherBaseUrl,
        userAgent: matomoTrackerUserAgent,
        tokenAuth: matomoDispatcherToken,
        httpClient: mockHttpClient,
        log: mockLogger,
      );

      await matomoDispatcher.sendBatch(
        actions:
            actions.map((action) => action.toMap(mockMatomoTracker)).toList(),
        customHeaders: mockMatomoTracker.customHeaders,
      );

      verify(
        () => mockHttpClient.post(
          any(),
          headers: any(
            named: 'headers',
            that: containsPair(
              MatomoDispatcher.userAgentHeaderKeys,
              matomoTrackerUserAgent,
            ),
          ),
          body: any(named: 'body'),
        ),
      );
    });

    test(
        'it should send nothing in sendBatch if the list of MatomoAction is empty',
        () async {
      final matomoDispatcher = MatomoDispatcher(
        baseUrl: matomoDispatcherBaseUrl,
        userAgent: matomoTrackerUserAgent,
        tokenAuth: matomoDispatcherToken,
        httpClient: mockHttpClient,
        log: mockLogger,
      );

      await matomoDispatcher.sendBatch(
        actions: [],
        customHeaders: mockMatomoTracker.customHeaders,
      );

      verifyNever(
        () => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );
    });
  });

  test('it should not throw exception if something wrong happen in sendBatch',
      () async {
    when(
      () => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => throw Exception());
    final matomoDispatcher = MatomoDispatcher(
      baseUrl: matomoDispatcherBaseUrl,
      userAgent: matomoTrackerUserAgent,
      tokenAuth: matomoDispatcherToken,
      httpClient: mockHttpClient,
      log: mockLogger,
    );

    await expectLater(
      matomoDispatcher.sendBatch(
        actions: [mockMatomoAction, mockMatomoAction]
            .map((action) => action.toMap(mockMatomoTracker))
            .toList(),
        customHeaders: mockMatomoTracker.customHeaders,
      ),
      completes,
    );
  });

  test('it should add the tokenAuth to Uri if it is not null', () {
    final matomoDispatcher = MatomoDispatcher(
      baseUrl: matomoDispatcherBaseUrl,
      userAgent: matomoTrackerUserAgent,
      tokenAuth: matomoDispatcherToken,
      httpClient: mockHttpClient,
      log: mockLogger,
    );

    final uri = matomoDispatcher
        .buildUriForAction(mockMatomoAction.toMap(mockMatomoTracker));

    expect(
      uri.queryParameters[MatomoDispatcher.tokenAuthUriKey],
      matomoDispatcherToken,
    );
  });

  test('it should not add the tokenAuth to Uri if it is null', () {
    final matomoDispatcher = MatomoDispatcher(
      baseUrl: matomoDispatcherBaseUrl,
      userAgent: matomoTrackerUserAgent,
      httpClient: mockHttpClient,
      log: mockLogger,
    );

    final uri = matomoDispatcher
        .buildUriForAction(mockMatomoAction.toMap(mockMatomoTracker));

    expect(
      uri.queryParameters.containsKey(MatomoDispatcher.tokenAuthUriKey),
      false,
    );
  });

  test('should use customHeaders from the tracker', () async {
    when(() => mockMatomoTracker.customHeaders).thenReturn({
      headerKey: headerValue,
    });

    final matomoDispatcher = MatomoDispatcher(
      baseUrl: matomoDispatcherBaseUrl,
      userAgent: matomoTrackerUserAgent,
      tokenAuth: matomoDispatcherToken,
      httpClient: mockHttpClient,
      log: mockLogger,
    );

    await matomoDispatcher.sendBatch(
      actions: [mockMatomoAction]
          .map((action) => action.toMap(mockMatomoTracker))
          .toList(),
      customHeaders: mockMatomoTracker.customHeaders,
    );

    verify(
      () => mockHttpClient.post(
        any(),
        headers: any(
          named: 'headers',
          that: containsPair(headerKey, headerValue),
        ),
        body: any(named: 'body'),
      ),
    );
  });
}
