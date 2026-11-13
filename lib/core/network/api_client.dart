import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config/app_config.dart';

class ApiClient {
  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _getBaseUrl(),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
          headers: {'Accept': 'application/json', 'X-Client': 'mobile'},
        ),
      );

  final Dio _dio;

  static String _getBaseUrl() {
    final url = AppConfig.apiBaseUrl.trim();
    final uri = Uri.tryParse(url);

    // The development server can use HTTP; production must use HTTPS.
    final allowHttp = kDebugMode && uri?.scheme == 'http';
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !allowHttp)) {
      throw StateError(
        kDebugMode
            ? 'Set API_BASE_URL to a valid HTTP or HTTPS API URL.'
            : 'A valid HTTPS API URL is required outside debug builds.',
      );
    }

    return '${url.replaceFirst(RegExp(r"/+$"), "")}/';
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> data,
    String? token,
  }) async {
    final response = await _dio.post<dynamic>(
      endpoint,
      data: data,
      options: Options(
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      ),
    );

    final body = response.data;

    if (body is Map<String, dynamic>) {
      return body;
    }

    throw const FormatException('Invalid API response.');
  }
}
