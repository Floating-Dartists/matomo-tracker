import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:matomo_tracker/src/matomo.dart';
import 'package:matomo_tracker/src/matomo_event.dart';

class MatomoDispatcher {
  MatomoDispatcher(
    String baseUrl,
    this.tokenAuth, {
    http.Client? httpClient,
  })  : baseUri = Uri.parse(baseUrl),
        httpClient = httpClient ?? http.Client();
  final String? tokenAuth;
  final http.Client httpClient;

  final Uri baseUri;

  static const tokenAuthUriKey = 'token_auth';
  static const userAgentHeaderKeys = 'User-Agent';

  /// Sends a batch of events to the Matomo server.
  ///
  /// The events are sent in a single request.
  ///
  /// Returns `true` if the batch was sent successfully.
  Future<bool> sendBatch(
    List<MatomoEvent> events,
    MatomoTracker tracker,
  ) async {
    if (events.isEmpty) return true;

    final userAgent = tracker.userAgent;
    final headers = <String, String>{
      if (!kIsWeb && userAgent != null) userAgentHeaderKeys: userAgent,
      ...tracker.customHeaders,
    };

    final batch = {
      "requests": [
        for (final event in events)
          "?${buildUriForEvent(event, tracker).query}",
      ],
    };
    tracker.log.fine(' -> $batch');
    try {
      final response = await httpClient.post(
        baseUri,
        headers: headers,
        body: jsonEncode(batch),
      );
      final statusCode = response.statusCode;
      tracker.log.fine(' <- $statusCode');

      return true;
    } catch (e) {
      tracker.log.severe(
        message: ' <- $e',
        error: e,
      );
      return false;
    }
  }

  @visibleForTesting
  Uri buildUriForEvent(MatomoEvent event, MatomoTracker tracker) {
    final queryParameters = Map<String, String>.from(baseUri.queryParameters)
      ..addAll(event.toMap(tracker));
    final aTokenAuth = tokenAuth;
    if (aTokenAuth != null) {
      queryParameters.addEntries([MapEntry(tokenAuthUriKey, aTokenAuth)]);
    }

    return baseUri.replace(queryParameters: queryParameters);
  }
}
