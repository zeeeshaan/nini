import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config/app_config.dart';

class ApiClient {
  ApiClient();

  // Configuration errors belong to the recoverable request flow, not widget creation.
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json', 'X-Client': 'mobile'},
    ),
  );

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
    Map<String, dynamic>? data,
    String? token,
  }) async {
    if (token != null &&
        (token.trim().isEmpty || token.contains(RegExp(r'[\r\n]')))) {
      throw const FormatException('Invalid authentication credential.');
    }
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

  Future<Map<String, dynamic>> get(String endpoint, {required String token}) =>
      _get(endpoint, token: token);

  Future<Map<String, dynamic>> getPublic(String endpoint, {String? token}) {
    if (token != null &&
        (token.trim().isEmpty || token.contains(RegExp(r'[\r\n]')))) {
      throw const FormatException('Invalid authentication credential.');
    }
    return _get(endpoint, token: token);
  }

  Future<Map<String, dynamic>> _get(String endpoint, {String? token}) async {
    final cancellation = CancelToken();
    final response = await _dio
        .get<dynamic>(
          endpoint,
          options: Options(
            headers: token == null ? null : {'Authorization': 'Bearer $token'},
          ),
          cancelToken: cancellation,
        )
        .timeout(
          const Duration(seconds: 35),
          onTimeout: () {
            cancellation.cancel();
            throw TimeoutException('Session check timed out.');
          },
        );
    final body = response.data;
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('Invalid API response.');
  }

  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required FormData data,
    required String token,
  }) async {
    if (token.trim().isEmpty || token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid authentication credential.');
    }
    final response = await _dio.post<dynamic>(
      endpoint,
      data: data,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
        sendTimeout: const Duration(seconds: 30),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    final body = response.data;
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('Invalid API response.');
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> data,
    required String token,
  }) async {
    if (token.trim().isEmpty || token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid authentication credential.');
    }
    final response = await _dio.patch<dynamic>(
      endpoint,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final body = response.data;
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('Invalid API response.');
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> data,
    required String token,
  }) async {
    if (token.trim().isEmpty || token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid authentication credential.');
    }
    final response = await _dio.put<dynamic>(
      endpoint,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final body = response.data;
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('Invalid API response.');
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
  }) async {
    if (token.trim().isEmpty || token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid authentication credential.');
    }
    final response = await _dio.delete<dynamic>(
      endpoint,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final body = response.data;
    if (body is Map<String, dynamic>) return body;
    throw const FormatException('Invalid API response.');
  }
}
