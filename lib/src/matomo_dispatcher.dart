import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:matomo_tracker/src/logger/logger.dart';

/// Will be invoked with the list of serialized actions and should return
/// the final payload to be sent to Matomo.
///
/// The final result needs to adhere to the format of the body of [http.BaseClient._sendUnstreamed].
/// - `String` for sending as JSON string
/// - `Map<String, String>` for sending as form data
/// - `List<int>` for sending as bytes
typedef MatomoSerializer = dynamic Function(List<Map<String, String>> actions);

class MatomoDispatcher {
  MatomoDispatcher({
    required String baseUrl,
    required this.log,
    this.userAgent,
    this.tokenAuth,
    http.Client? httpClient,
    this.serializer,
  })  : baseUri = Uri.parse(baseUrl),
        httpClient = httpClient ?? http.Client();

  final String? tokenAuth;
  final http.Client httpClient;
  final Uri baseUri;
  final String? userAgent;
  final Logger log;
  final MatomoSerializer? serializer;

  static const tokenAuthUriKey = 'token_auth';
  static const userAgentHeaderKeys = 'User-Agent';

  /// Serializes the given actions using the provided [serializer] or
  /// the default serialization method.
  ///
  /// The default serialization method sends the actions as a JSON
  /// payload in the format expected by Matomo.
  dynamic serializeActions(List<Map<String, String>> actions) {
    if (serializer != null) {
      return serializer!(actions);
    }

    final batch = {
      'requests': [
        for (final action in actions) '?${buildUriForAction(action).query}',
      ],
    };
    return jsonEncode(batch);
  }

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

    final batch = serializeActions(actions);
    log.fine(' -> $batch');
    try {
      final response = await httpClient.post(
        baseUri,
        headers: headers,
        body: batch,
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

  MatomoDispatcher copyWith({
    String? baseUrl,
    String? tokenAuth,
    String? userAgent,
    Logger? log,
    http.Client? httpClient,
    MatomoSerializer? serializer,
  }) {
    return MatomoDispatcher(
      baseUrl: baseUrl ?? baseUri.toString(),
      tokenAuth: tokenAuth ?? this.tokenAuth,
      userAgent: userAgent ?? this.userAgent,
      log: log ?? this.log,
      httpClient: httpClient ?? this.httpClient,
      serializer: serializer ?? this.serializer,
    );
  }
}
