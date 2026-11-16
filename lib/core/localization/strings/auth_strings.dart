/// Shared copy for phone/email login and OTP verification.
abstract final class AuthStrings {
  static const brand = "های‌ورک";
  static const logo = "نشان های‌ورک";
  static const loading = "در حال بارگذاری";
  static const sessionRestoreFailed =
      'بررسی نشست ورود انجام نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';
  static const retrySession = 'تلاش دوباره';
  static const login = "ورود";
  static const loginWithGoogle = "ورود با گوگل";
  static const loginWithEmail = "ادامه با ایمیل";
  static const email = "نشانی ایمیل";
  static const emailRequired = "نشانی ایمیل خود را وارد کنید.";
  static const invalidEmail = "نشانی ایمیل معتبر وارد کنید.";
  static const emailOtpSent = "کد تأیید به ایمیل شما ارسال شد.";
  static const mobile = "شماره همراه";
  static const phoneRequired = "شماره همراه خود را وارد کنید.";
  static const done = "تأیید";
  static const enterOtp = "کد تأیید را وارد کنید";
  static const continueLabel = "ادامه";
  static const selectCountry = "انتخاب کشور";
  static const searchCountry = "جستجوی کشورها";
  static const noCountries = "کشوری یافت نشد.";
  static const resendCode = "ارسال دوباره کد";
  static const resendCountdown = "زمان باقی‌مانده تا ارسال دوباره";
  static String codeFor(String phone) => 'کد تأیید برای $phone';
  static String codeSentTo(String email) =>
      'کد ارسال‌شده به \u2066$email\u2069 را وارد کنید';
}
