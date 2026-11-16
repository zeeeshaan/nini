import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/otp_verification_repo.dart';

class OtpVerificationState {
  const OtpVerificationState({
    this.code = '',
    this.isLoading = false,
    this.isVerified = false,
    this.errorMessage,
  });

  final String code;
  final bool isLoading;
  final bool isVerified;
  final String? errorMessage;

  bool get canVerify =>
      RegExp(r'^[0-9۰-۹٠-٩]{6}$').hasMatch(code) && !isLoading && !isVerified;
}

class OtpVerificationCubit extends Cubit<OtpVerificationState> {
  OtpVerificationCubit(this._repository) : super(const OtpVerificationState());

  final OtpVerificationRepository _repository;

  void changeCode(String code) {
    if (state.isLoading || state.isVerified) return;

    emit(OtpVerificationState(code: code));
  }

  Future<void> verifyOtp(String phone) => _verifyOtp(phone);

  Future<void> verifyEmailOtp(String email) =>
      _verifyOtp(email, useEmail: true);

  Future<void> _verifyOtp(String identifier, {bool useEmail = false}) async {
    if (!state.canVerify) return;

    final code = state.code;

    emit(OtpVerificationState(code: code, isLoading: true));

    try {
      if (useEmail) {
        await _repository.verifyEmailOtp(email: identifier, code: code);
      } else {
        await _repository.verifyOtp(phone: identifier, code: code);
      }

      if (isClosed) return;

      emit(OtpVerificationState(code: code, isVerified: true));
    } on DioException catch (error) {
      if (isClosed) return;

      emit(
        OtpVerificationState(code: code, errorMessage: _errorMessage(error)),
      );
    } catch (_) {
      if (isClosed) return;

      emit(
        OtpVerificationState(
          code: code,
          errorMessage: "تأیید کد انجام نشد. دوباره تلاش کنید.",
        ),
      );
    }
  }

  String _errorMessage(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
      case 401:
      case 422:
        return "کد تأیید معتبر نیست. کد را بررسی کنید.";
      case 410:
        return "کد تأیید منقضی شده است. کد جدید درخواست کنید.";
      case 429:
        return "تعداد تلاش‌ها بیش از حد مجاز است. بعداً دوباره تلاش کنید.";
      default:
        return "اتصال برقرار نشد. دوباره تلاش کنید.";
    }
  }
}
