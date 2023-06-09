import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:matomo_tracker/src/logger/logger.dart';

class MatomoDispatcher {
  MatomoDispatcher({
    required String baseUrl,
    required this.log,
    this.userAgent,
    this.tokenAuth,
    http.Client? httpClient,
  })  : baseUri = Uri.parse(baseUrl),
        httpClient = httpClient ?? http.Client();

  final String? tokenAuth;
  final http.Client httpClient;
  final Uri baseUri;
  final String? userAgent;
  final Logger log;

  static const tokenAuthUriKey = 'token_auth';
  static const userAgentHeaderKeys = 'User-Agent';

  /// Sends a batch of actions to the Matomo server.
  ///
  /// The actions are sent in a single request.
  ///
  /// Returns `true` if the batch was sent successfully.
  /// Note that this is based on the http return code of the
  /// response, not its body.
  Future<bool> sendBatch({
    required List<Map<String, String>> actions,
    Map<String, String> customHeaders = const {},
  }) async {
    if (actions.isEmpty) return true;

    final userAgent = this.userAgent;
    final headers = <String, String>{
      if (!kIsWeb && userAgent != null) userAgentHeaderKeys: userAgent,
      ...customHeaders,
    };

    final batch = {
      'requests': [
        for (final action in actions) '?${buildUriForAction(action).query}',
      ],
    };
    log.fine(' -> $batch');
    try {
      final response = await httpClient.post(
        baseUri,
        headers: headers,
        body: jsonEncode(batch),
      );
      final statusCode = response.statusCode;
      log.fine(' <- $statusCode');

      return true;
    } catch (e) {
      log.severe(
        message: ' <- $e',
        error: e,
      );
      return false;
    }
  }

  @visibleForTesting
  Uri buildUriForAction(Map<String, String> action) {
    final queryParameters = Map<String, String>.from(baseUri.queryParameters)
      ..addAll(action);
    final aTokenAuth = tokenAuth;
    if (aTokenAuth != null) {
      queryParameters.addEntries([MapEntry(tokenAuthUriKey, aTokenAuth)]);
    }

    return baseUri.replace(queryParameters: queryParameters);
  }
}
