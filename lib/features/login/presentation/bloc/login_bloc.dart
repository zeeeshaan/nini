import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/auth_strings.dart';

import '../../data/auth_repo.dart';
import 'login_event.dart';
import 'login_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<OtpRequested>(_onOtpRequested);
    on<EmailOtpRequested>(_onEmailOtpRequested);
  }

  final AuthRepository _repository;

  Future<void> _onOtpRequested(OtpRequested event, Emitter<AuthState> emit) =>
      _requestOtp(event.phone, emit);

  Future<void> _onEmailOtpRequested(
    EmailOtpRequested event,
    Emitter<AuthState> emit,
  ) => _requestOtp(event.email, emit, useEmail: true);

  Future<void> _requestOtp(
    String identifier,
    Emitter<AuthState> emit, {
    bool useEmail = false,
  }) async {
    if (state is AuthLoading) return;

    emit(const AuthLoading());

    try {
      final value = useEmail
          ? await _repository.requestEmailOtp(identifier)
          : await _repository.requestOtp(identifier);

      emit(
        useEmail ? EmailOtpRequestAccepted(value) : OtpRequestAccepted(value),
      );
    } on FormatException {
      emit(
        AuthFailure(
          useEmail ? AuthStrings.invalidEmail : 'Enter a valid phone number.',
        ),
      );
    } on DioException catch (error) {
      emit(AuthFailure(_networkError(error, useEmail: useEmail)));
    } catch (_) {
      emit(const AuthFailure('Unable to request OTP. Try again.'));
    }
  }

  String _networkError(DioException error, {required bool useEmail}) {
    switch (error.response?.statusCode) {
      case 400:
      case 422:
        return useEmail ? AuthStrings.invalidEmail : 'Invalid phone number.';
      case 429:
        return 'Too many attempts. Please try again later.';
      case 500:
      case 502:
      case 503:
        return 'Server unavailable. Please try again.';
      default:
        return 'Connection failed. Please try again.';
    }
  }
}
