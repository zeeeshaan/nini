/// Persian labels and feedback for the profile editor.
abstract final class ProfileEditStrings {
  static const title = 'تنظیمات پروفایل';
  static const name = 'نام';
  static const lastName = 'نام خانوادگی';
  static const businessType = 'نوع فروشگاه / کسب‌وکار';
  static const nationality = 'ملیت';
  static const city = 'شهر';
  static const username = 'نام کاربری';
  static const email = 'ایمیل';
  static const birth = 'تاریخ تولد';
  static const clearBirthDate = 'پاک کردن تاریخ';
  static const gender = 'جنسیت';
  static const bio = 'بیوگرافی';
  static const cancel = 'لغو';
  static const choosePhoto = 'انتخاب تصویر پروفایل';
  static const cropPhoto = 'برش تصویر پروفایل';
  static const photoError =
      'آماده‌سازی تصویر پروفایل ممکن نشد. دوباره تلاش کنید.';
  static const saved = 'پروفایل به‌روزرسانی شد';
  static const saveFailed =
      'ذخیره پروفایل ممکن نشد. دوباره تلاش کنید.';
  static const loadFailed =
      'بارگذاری پروفایل ممکن نشد. دوباره تلاش کنید.';
  static const photoUploadUnavailable =
      'آپلود تصویر در دسترس نیست (۴۰۴). پروفایل شما تغییر نکرد. ویرایش‌ها و پیش‌نمایش تصویر هنوز در فرم هستند.';
  static const photoUploadFailed =
      'سرور آپلود تصویر را تأیید نکرد. پروفایل شما تغییر نکرد. دوباره تلاش کنید.';
  static const invalidPhoto =
      'یک تصویر پروفایل JPG، PNG یا WebP انتخاب کنید.';
  static const photoTooLarge =
      'حجم تصویر پروفایل نباید بیشتر از ۵ مگابایت باشد.';
  static const photoUploadLimited =
      'آپلود تصویر بیش از حد انجام شده. چند دقیقه صبر کنید و دوباره تلاش کنید.';
  static const saveTextOnlyTitle = 'فقط تغییرات متن ذخیره شود؟';
  static const saveTextOnlyMessage =
      'آپلود تصویر در دسترس نیست. می‌توانید تغییرات متن را جداگانه ذخیره کنید و پیش‌نمایش تصویر را نگه دارید. تصویر آپلود نمی‌شود.';
  static const saveTextOnly = 'فقط ذخیره متن';
  static const textSavedPhotoPending =
      'متن پروفایل ذخیره شد. تصویر انتخاب‌شده آپلود نشده؛ پیش‌نمایش آن هنوز اینجاست.';
  static const genderMale = 'مرد';
  static const genderFemale = 'زن';
  static const genderOther = 'سایر';

  /// Show API gender values in Persian without changing stored keys.
  static String genderDisplay(String value) => switch (value.trim()
      .toLowerCase()) {
    'male' || 'مرد' => genderMale,
    'female' || 'زن' => genderFemale,
    'other' || 'سایر' => genderOther,
    _ => value,
  };

  /// Map typed/displayed gender back to API values.
  static String genderApi(String value) => switch (value.trim().toLowerCase()) {
    'male' || 'مرد' || 'm' => 'male',
    'female' || 'زن' || 'f' => 'female',
    'other' || 'سایر' => 'other',
    _ => value.trim(),
  };

  static String fieldsNotConfirmed(
    Iterable<String> fields, {
    Iterable<String> confirmed = const [],
    bool verificationFailed = false,
  }) =>
      '${verificationFailed ? 'به‌روزرسانی پذیرفته شد، اما تأیید خواندن شکست خورد. ' : ''}'
      '${confirmed.isEmpty ? '' : 'تأییدشده توسط سرور: ${confirmed.join('، ')}. '}'
      'سرور ذخیره این موارد را تأیید نکرد: ${fields.join('، ')}. ویرایش‌های تأییدنشده هنوز در فرم هستند.';

  static String validationFields(Iterable<String> fields) =>
      'سرور این موارد را رد کرد: ${fields.join('، ')}. این مقادیر را بررسی کنید. ویرایش‌ها هنوز در فرم هستند.';

  static String? fieldLabel(String field) => switch (field) {
    'name' || 'firstName' || 'lastName' => name,
    'username' => username,
    'email' => email,
    'nationality' => nationality,
    'businessType' => businessType,
    'bio' => bio,
    'city' => city,
    'birthDate' => birth,
    'gender' => gender,
    'avatarUrl' => 'تصویر پروفایل',
    _ => null,
  };

  static const invalidName = 'نام کامل حداکثر ۸۰ نویسه باشد.';
  static const invalidUsername =
      'برای نام کاربری ۳ تا ۳۰ حرف کوچک، عدد، زیرخط یا نقطه استفاده کنید. نام کاربری موجود را نمی‌توان خالی کرد.';
  static const invalidBio = 'بیوگرافی حداکثر ۵۰۰ نویسه باشد.';
  static const invalidCity = 'شهر حداکثر ۸۰ نویسه باشد.';
  static const invalidBusinessType =
      'نوع کسب‌وکار باید ۲ تا ۶۰ نویسه باشد یا خالی بماند.';
  static const invalidGender =
      'مرد، زن یا سایر را وارد کنید، یا جنسیت را خالی بگذارید.';
  static const usernameTaken = 'این نام کاربری قبلاً گرفته شده است.';
  static const invalidFields =
      'سرور به‌روزرسانی پروفایل را رد کرد. مقادیر واردشده را بررسی کنید و دوباره تلاش کنید. ویرایش‌ها هنوز در فرم هستند.';
  static const sessionExpired =
      'جلسه شما منقضی شده است. لطفاً دوباره وارد شوید.';
  static const connectionFailed =
      'اتصال به سرور ممکن نشد. اتصال خود را بررسی کنید و دوباره تلاش کنید.';
  static const timeout =
      'درخواست پروفایل زمان‌بر شد. دوباره تلاش کنید.';
}
