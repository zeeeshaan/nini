import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';
import 'package:hywork/shared/models/post/post_unit.dart';

/// Persian copy for the Post Detail screen only. Do not use for layout.
abstract final class PostDetailStrings {
  static const quantity = 'تعداد';
  static const increaseQuantity = 'افزایش تعداد';
  static const back = 'بازگشت';
  static const message = 'پیام';
  static const morePostOptions = 'گزینه‌های بیشتر پست';
  static const profile = 'پروفایل';
  static const viewAnalytics = 'مشاهده آمار';
  static const unavailable = 'پست در دسترس نیست. برای تلاش مجدد ضربه بزنید.';
  static const like = 'پسندیدن';
  static const unlike = 'لغو پسند';
  static const likeFailed = 'به‌روزرسانی پسند ممکن نشد. دوباره تلاش کنید.';
  static const bookmark = 'ذخیره پست';
  static const removeBookmark = 'حذف از ذخیره‌ها';
  static const comments = 'نظرات';
  static const share = 'اشتراک‌گذاری';
  static const addToCart = 'افزودن به سبد';
  static const removeFromCart = 'حذف از سبد';
  static const cartAdded = 'به سبد اضافه شد';
  static const cartRemoved = 'از سبد حذف شد';
  static const cartStorageError =
      'فضای ذخیره‌سازی در دسترس نیست. تغییرات شما هنوز ذخیره نشده است.';
  static const cartStockExceeded = 'این تعداد از موجودی موجود بیشتر است.';
  static const postUnrated = 'هنوز امتیاز داده نشده';
  static const featuresHeading = 'مشخصات';
  static const serviceDescription = 'توضیحات';
  static const serviceType = 'نوع خدمت';
  static const serviceUnit = 'واحد خدمت';
  static const serviceMinimumOrder = 'حداقل سفارش';
  static const serviceArea = 'محدوده خدمت';
  static const unitSession = 'جلسه';
  static const toman = AppStrings.tomanPersian;
  static const authorName = 'پایپ‌مستر';
  static const authorLocation = 'تهران، ایران';
  static const postTitle = 'عنوان: تعمیر شیر آب چکه مثل حرفه‌ای‌ها!';
  static const visualSuggestion =
      'پیشنهاد تصویر: شیر آب چکه و لوله‌کش حرفه‌ای با ابزار، یا عکس‌های قبل و بعد تعمیر.';
  static const captionHeading = 'توضیحات:';
  static const caption =
      'از چکه مداوم شیر آب خسته شده‌اید؟ نگذارید نشتی‌های کوچک به مشکلات بزرگ تبدیل شوند. لوله‌کش‌های باتجربه ما تعمیر سریع، قابل اعتماد و مقرون‌به‌صرفه شیر آب را برای خانه و کسب‌وکار انجام می‌دهند.';
  static const serviceBenefits =
      'سرویس سریع و کارآمد\nقیمت مناسب\nلوله‌کش‌های باتجربه و دارای مجوز';
  static const booking =
      'همین امروز سرویس را رزرو کنید و با نشتی خداحافظی کنید! با [شماره تلفن] تماس بگیرید یا به [وب‌سایت] سر بزنید.';
  static const hashtagsHeading = 'برچسب‌ها / کلیدواژه‌ها:';
  static const hashtags =
      '#لوله‌کشی #تعمیرشیر #رفع‌نشتی #لوله‌کش‌اضطراری #تعمیرلوله #نگهداری‌خانه #لوله‌کش‌محلی';
  static const callToActionHeading = 'فراخوان اقدام:';
  static const callToAction =
      'همین حالا برای هماهنگی تعمیر شیر تماس بگیرید و از خانه‌ای بدون نشتی لذت ببرید!';
  static const features = <(String, String)>[
    ('برند', 'اپل، سامسونگ، شیائومی'),
    ('مدل', 'آیفون ۱۵ پرو'),
    ('سال عرضه', '۲۰۲۴'),
    ('وضعیت', 'نو، کارکرده'),
    ('رنگ', 'مشکی، نقره‌ای، آبی'),
    ('جنس بدنه', 'آلومینیوم، شیشه، پلاستیک'),
    ('وزن', '۱۸۷ گرم'),
    ('ابعاد', '۱۴۶٫۶ × ۷۰٫۶ × ۷٫۸ میلی‌متر'),
  ];
  static const commentMaybePosted =
      'این نظر شاید قبلاً ثبت شده باشد. قبل از تلاش دوباره همه نظرات را بررسی کنید.';
  static const commentUnconfirmed =
      'ثبت نظر تأیید نشد. قبل از تلاش دوباره همه نظرات را بررسی کنید؛ می‌توانید نظر دیگری بفرستید.';
  static const commentPostFailed = 'ارسال نظر ممکن نشد.';
  static const commentDeleteUnconfirmed = 'حذف نظر تأیید نشد.';

  static String postRating(String value) =>
      'امتیاز ${AppStrings.persianDigits(value)} از ۵';
  static String viewSellerProfile(String name) => 'مشاهده پروفایل $name';
  static String scheduledFor(String date) => 'زمان‌بندی‌شده برای: $date';
  static String postCategory(String category) =>
      HomeStrings.postCategory(category);

  static String unit(PostUnit unit) => switch (unit) {
    PostUnit.piece || PostUnit.item => 'عدد',
    PostUnit.hour => 'ساعت',
    PostUnit.day => 'روز',
    PostUnit.session => 'جلسه',
    PostUnit.project => 'پروژه',
    PostUnit.meter => 'متر',
    PostUnit.centimeter => 'سانتی‌متر',
    PostUnit.kilogram => 'کیلوگرم',
    PostUnit.set => 'ست',
  };

  static String persianDigits(String value) => AppStrings.persianDigits(value);
}
