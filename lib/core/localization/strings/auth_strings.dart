/// Shared copy for phone/email login and OTP verification.
abstract final class AuthStrings {
  static const brand = 'HYWORK';
  static const logo = "HYWORK logo";
  static const loading = "Loading";
  static const sessionRestoreFailed =
      'Could not verify your session. Check your internet connection and try again.';
  static const retrySession = 'Try again';
  static const login = "Login";
  static const loginWithGoogle = 'Login with Google';
  static const loginWithEmail = 'Continue with email';
  static const email = 'Email address';
  static const emailRequired = 'Enter your email address.';
  static const invalidEmail = 'Enter a valid email address.';
  static const emailOtpSent = 'Verification code sent to your email.';
  static const mobile = "Mobile number";
  static const phoneRequired = "Enter your mobile number.";
  static const done = "Done";
  static const enterOtp = "Enter your OTP";
  static const continueLabel = "Continue";
  static const selectCountry = "Select country";
  static const searchCountry = "Search countries";
  static const noCountries = "No countries found.";
  static const resendCode = "Resend code";
  static const resendCountdown = "Time until resend";
  static String codeFor(String phone) => 'Verification code for $phone';
  static String codeSentTo(String email) => 'Enter the code sent to $email';
}
