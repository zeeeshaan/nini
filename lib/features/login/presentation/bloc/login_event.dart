sealed class AuthEvent {
  const AuthEvent();
}

final class OtpRequested extends AuthEvent {
  const OtpRequested(this.phone);

  final String phone;
}

final class EmailOtpRequested extends AuthEvent {
  const EmailOtpRequested(this.email);

  final String email;
}
