import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper around the home hub server's HTTP API.
class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
    : _baseUri = Uri.parse(baseUrl),
      _http = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _http;

  Uri get baseUri => _baseUri;

  /// Calls `GET /` on the server and returns the decoded JSON body.
  Future<Map<String, dynamic>> getRoot() async {
    final response = await _http
        .get(_baseUri.resolve('/'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}
