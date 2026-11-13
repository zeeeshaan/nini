import 'package:nini/core/network/api_client.dart';

import '../domain/email_address.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

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
