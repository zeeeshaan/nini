/// Persian copy for phone/email login and OTP verification.
abstract final class AuthStrings {
  static const brand = 'های‌ورک';
  static const logo = 'لوگوی های‌ورک';
  static const loading = 'در حال بارگذاری';
  static const sessionRestoreFailed =
      'نتوانستیم نشست شما را تأیید کنیم. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';
  static const retrySession = 'تلاش مجدد';
  static const login = 'ورود';
  static const loginWithGoogle = 'ورود با گوگل';
  static const loginWithEmail = 'ادامه با ایمیل';
  static const email = 'آدرس ایمیل';
  static const emailRequired = 'آدرس ایمیل خود را وارد کنید.';
  static const invalidEmail = 'یک آدرس ایمیل معتبر وارد کنید.';
  static const emailOtpSent = 'کد تأیید به ایمیل شما ارسال شد.';
  static const mobile = 'شماره موبایل';
  static const phoneRequired = 'شماره موبایل خود را وارد کنید.';
  static const invalidPhone = 'یک شماره موبایل معتبر وارد کنید.';
  static const otpRequestFailed = 'درخواست کد ممکن نشد. دوباره تلاش کنید.';
  static const tooManyAttempts =
      'تلاش‌های زیادی انجام شده است. لطفاً بعداً دوباره تلاش کنید.';
  static const serverUnavailable =
      'سرور در دسترس نیست. لطفاً دوباره تلاش کنید.';
  static const connectionFailed =
      'اتصال برقرار نشد. لطفاً دوباره تلاش کنید.';
  static const done = 'تأیید';
  static const enterOtp = 'کد تأیید را وارد کنید';
  static const continueLabel = 'ادامه';
  static const selectCountry = 'انتخاب کشور';
  static const searchCountry = 'جستجوی کشورها';
  static const noCountries = 'کشوری یافت نشد.';
  static const resendCode = 'ارسال مجدد کد';
  static const resendCountdown = 'زمان تا ارسال مجدد';
  static String codeFor(String phone) => 'کد تأیید برای $phone';
  static String codeSentTo(String email) => 'کد ارسال‌شده به $email را وارد کنید';
}
