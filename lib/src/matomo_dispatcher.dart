import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'matomo_event.dart';

class MatomoDispatcher {
  final String baseUrl;
  final String? tokenAuth;
  final http.Client httpClient;

  MatomoDispatcher(this.baseUrl, this.tokenAuth, {http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  void send(MatomoEvent event) {
    final userAgent = event.tracker.userAgent;
    final headers = <String, String>{
      if (!kIsWeb && userAgent != null) 'User-Agent': userAgent,
    };

    final map = event.toMap();
    final baseUri = Uri.parse(baseUrl)..queryParameters.addAll(map);
    final _tokenAuth = tokenAuth;
    if (_tokenAuth != null) {
      baseUri.queryParameters.addEntries([MapEntry('token_auth', _tokenAuth)]);
    }
    event.tracker.log.fine(' -> ${baseUri.toString()}');
    httpClient.post(baseUri, headers: headers).then((http.Response response) {
      final statusCode = response.statusCode;
      event.tracker.log.fine(' <- $statusCode');
    }).catchError((e) {
      event.tracker.log.fine(' <- ${e.toString()}');
    });
  }
}
