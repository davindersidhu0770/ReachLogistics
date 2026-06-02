import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('${ApiConstants.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Try to extract the error message from the response body
    String message = 'Request failed (${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final msg = body['message'] as String?;
        if (msg != null && msg.isNotEmpty) message = msg;
      }
    } catch (_) {}

    throw Exception(message);
  }
}
