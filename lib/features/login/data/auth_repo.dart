import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:dio/dio.dart';

import '../domain/email_address.dart';

class AuthRepository {
  AuthRepository(this._apiClient, {SecureTokenStore? tokenStore})
    : _tokenStore = tokenStore ?? SecureTokenStore();

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;

  /// A stored credential is never enough to open the authenticated app.
  Future<String?> restoreSession() async {
    final stored = await _tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    );
    final token = stored?.trim();
    if (token == null || token.isEmpty) return null;
    if (token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Invalid stored credential.');
    }

    late final Map<String, dynamic> response;
    try {
      response = await _apiClient.get('auth/me', token: token);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      await _tokenStore.deleteToken();
      return null;
    }

    if (response['success'] != true) {
      throw const FormatException('Session was not confirmed.');
    }
    final data = response['data'];
    // /auth/me returns the user directly; OTP responses can nest it under user.
    final user = data is Map ? data['user'] ?? data : null;
    final id = user is Map ? user['id'] : null;
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Authenticated user identity is missing.');
    }
    // Preserve a replacement credential only after validating the response identity.
    final replacement = (data as Map)['token'];
    if (replacement != null) {
      if (replacement is! String ||
          replacement.trim().isEmpty ||
          replacement.contains(RegExp(r'[\r\n]'))) {
        throw const FormatException('Invalid session credential.');
      }
      if (replacement.trim() != token) {
        await _tokenStore.saveToken(replacement.trim());
      }
    }
    return id.trim();
  }

  Future<String> requestOtp(String input) async {
    final phone = _normalizePhone(input);

    if (!RegExp(r'^09[0-9]{9}$').hasMatch(phone)) {
      throw const FormatException('Invalid phone number');
    }

    await _requestOtp({'phone': phone});
    return phone;
  }

  Future<String> requestEmailOtp(String input) async {
    final email = input.trim();
    if (!isValidEmailAddress(email)) {
      throw const FormatException('Invalid email address');
    }
    await _requestOtp({'email': email});
    return email;
  }

  Future<void> _requestOtp(Map<String, dynamic> identity) async {
    final response = await _apiClient.post('auth/request-otp', data: identity);

    if (response['success'] != true) {
      throw StateError('OTP request failed');
    }
  }

  String _normalizePhone(String input) {
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    var phone = input.trim().replaceAllMapped(RegExp(r'[۰-۹٠-٩]'), (match) {
      final digit = match.group(0)!;
      final persianIndex = persianDigits.indexOf(digit);

      final number = persianIndex >= 0
          ? persianIndex
          : arabicDigits.indexOf(digit);

      return number.toString();
    });

    phone = phone.replaceAll(RegExp(r'[\s()-]'), '');

    if (phone.startsWith('+98')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('0098')) {
      phone = phone.substring(4);
    } else if (phone.startsWith('98') && phone.length == 12) {
      phone = phone.substring(2);
    }

    return phone.startsWith('0') ? phone : '0$phone';
  }
}
