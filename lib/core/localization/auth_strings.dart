/// Entry-screen copy. Phone and OTP flows are local UI previews only.
abstract final class AuthStrings {
  static const brand = 'HYWORK';
  static const logo = "HYWORK logo";
  static const loading = "Loading";
  static const login = "Login";
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
}
