sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class OtpRequestAccepted extends AuthState {
  const OtpRequestAccepted(this.phone);

  final String phone;
}

final class EmailOtpRequestAccepted extends AuthState {
  const EmailOtpRequestAccepted(this.email);

  final String email;
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}
