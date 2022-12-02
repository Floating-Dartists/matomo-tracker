import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'matomo_event.dart';

class MatomoDispatcher {
  final String? tokenAuth;
  final http.Client httpClient;

  final Uri baseUri;

  static const tokenAuthUriKey = 'token_auth';
  static const userAgentHeaderKeys = 'User-Agent';

  MatomoDispatcher(
    String baseUrl,
    this.tokenAuth, {
    http.Client? httpClient,
  })  : baseUri = Uri.parse(baseUrl),
        httpClient = httpClient ?? http.Client();

  Future<void> send(MatomoEvent event) async {
    final headers = <String, String>{
      if (!kIsWeb) 'User-Agent': 'Dart Matomo Tracker',
    };

    final uri = buildUriForEvent(event);
    event.tracker.log.fine(' -> ${uri.toString()}');
    try {
      final response = await httpClient.post(uri, headers: headers);
      final statusCode = response.statusCode;
      event.tracker.log.fine(' <- $statusCode');
    } catch (e) {
      event.tracker.log.fine(' <- ${e.toString()}');
    }
  }

  Future<void> sendBatch(List<MatomoEvent> events) async {
    if (events.isEmpty) {
      return;
    }

    final userAgent = events.first.tracker.userAgent;
    final headers = <String, String>{
      if (!kIsWeb && userAgent != null) userAgentHeaderKeys: userAgent,
    };

    final batch = {
      "requests": [
        for (final event in events) "?${buildUriForEvent(event).query}",
      ],
    };
    events.first.tracker.log.fine(' -> ${batch.toString()}');
    try {
      final response = await httpClient.post(
        baseUri,
        headers: headers,
        body: jsonEncode(batch),
      );
      final statusCode = response.statusCode;
      events.first.tracker.log.fine(' <- $statusCode');
    } catch (e) {
      events.first.tracker.log.fine(' <- ${e.toString()}');
    }
  }

  @visibleForTesting
  Uri buildUriForEvent(MatomoEvent event) {
    final queryParameters = Map<String, String>.from(baseUri.queryParameters)
      ..addAll(event.toMap());
    final aTokenAuth = tokenAuth;
    if (aTokenAuth != null) {
      queryParameters.addEntries([MapEntry(tokenAuthUriKey, aTokenAuth)]);
    }

    return baseUri.replace(queryParameters: queryParameters);
  }
}
