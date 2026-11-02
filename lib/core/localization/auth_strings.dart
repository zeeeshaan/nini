/// Entry-screen copy. Phone and OTP flows are local UI previews only.
abstract final class AuthStrings {
  static const brand = 'HYWORK';
  static const logo = 'نشان های‌ورک';
  static const loading = 'در حال بارگذاری';
  static const login = 'ورود';
  static const mobile = 'شماره موبایل';
  static const phoneRequired = 'شماره موبایل را وارد کنید.';
  static const done = 'تأیید';
  static const enterOtp = 'کد تأیید را وارد کنید';
  static const continueLabel = 'ادامه';
  static const selectCountry = 'انتخاب کشور';
  static const searchCountry = 'جستجوی کشور';
  static const noCountries = 'کشوری پیدا نشد.';
  static const resendCode = 'ارسال مجدد';
  static const resendCountdown = 'زمان باقی‌مانده برای ارسال مجدد';
  static String codeFor(String phone) => 'کد تأیید برای $phone';
}
