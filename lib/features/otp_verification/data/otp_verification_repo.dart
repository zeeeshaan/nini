import 'package:nini/core/network/api_client/api_client.dart';
import 'package:nini/core/security/secure_token/secure_token.dart';
import 'package:nini/features/login/domain/email_address.dart';

class OtpVerificationRepository {
  OtpVerificationRepository(this._apiClient, this._tokenStore);

  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;

  Future<void> verifyOtp({required String phone, required String code}) =>
      _verifyOtp(identity: {'phone': _normalizePhone(phone)}, code: code);

  Future<void> verifyEmailOtp({required String email, required String code}) {
    final value = email.trim();
    if (!isValidEmailAddress(value)) {
      throw const FormatException('Invalid email address.');
    }
    return _verifyOtp(identity: {'email': value}, code: code);
  }

  Future<void> _verifyOtp({
    required Map<String, dynamic> identity,
    required String code,
  }) async {
    final normalizedCode = _toEnglishDigits(code);

    if (!RegExp(r'^[0-9]{6}$').hasMatch(normalizedCode)) {
      throw const FormatException('Enter a valid 6-digit OTP.');
    }

    final response = await _apiClient.post(
      'auth/verify-otp',
      data: {...identity, 'code': normalizedCode},
    );

    if (response['success'] != true) {
      throw StateError('OTP verification failed.');
    }

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid server response.');
    }

    final token = data['token'];

    if (token is! String ||
        token.trim().isEmpty ||
        token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('Authentication token missing.');
    }

    await _tokenStore.saveToken(token.trim());
  }

  String _normalizePhone(String input) {
    var phone = _toEnglishDigits(input.trim())
        .replaceAll(RegExp(r'[\s()-]'), '');

    if (phone.startsWith('+98')) {
      phone = '0${phone.substring(3)}';
    } else if (phone.startsWith('0098')) {
      phone = '0${phone.substring(4)}';
    } else if (phone.startsWith('98') && phone.length == 12) {
      phone = '0${phone.substring(2)}';
    } else if (phone.startsWith('9') && phone.length == 10) {
      phone = '0$phone';
    }

    if (!RegExp(r'^09[0-9]{9}$').hasMatch(phone)) {
      throw const FormatException('Invalid phone number.');
    }

    return phone;
  }

  String _toEnglishDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    return value.replaceAllMapped(RegExp(r'[۰-۹٠-٩]'), (match) {
      final digit = match.group(0)!;
      final persianIndex = persian.indexOf(digit);

      final number = persianIndex >= 0 ? persianIndex : arabic.indexOf(digit);

      return number.toString();
    });
  }
}
