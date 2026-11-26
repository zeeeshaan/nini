import 'package:hywork/core/localization/app_string/app_string.dart';

/// Persian copy for the Home feed only. Do not use for layout or alignment.
abstract final class HomeStrings {
  static const brand = 'های‌ورک';
  static const loadFailed = 'بارگذاری پست‌ها ممکن نشد. تلاش مجدد';
  static const empty = 'هنوز پستی نیست.';
  static const loadDetailsFailed = 'بارگذاری جزئیات پست ممکن نشد.';
  static const likeFailed = 'به‌روزرسانی پسند ممکن نشد. دوباره تلاش کنید.';
  static const saveFailed = 'به‌روزرسانی ذخیره‌ها ممکن نشد. دوباره تلاش کنید.';
  static const saved = 'پست ذخیره شد';
  static const like = 'پسندیدن';
  static const unlike = 'لغو پسند';
  static const bookmark = 'ذخیره پست';
  static const removeBookmark = 'حذف از ذخیره‌ها';
  static const comments = 'نظرات';
  static const share = 'اشتراک‌گذاری';
  static const rating = 'امتیاز';
  static const addToCart = 'افزودن به سبد';
  static const removeFromCart = 'حذف از سبد';
  static const cartAdded = 'به سبد اضافه شد';
  static const cartRemoved = 'از سبد حذف شد';
  static const viewCart = 'مشاهده سبد';
  static const cartStorageError =
      'فضای ذخیره‌سازی در دسترس نیست. تغییرات شما هنوز ذخیره نشده است.';
  static const cartStockExceeded = 'این تعداد از موجودی موجود بیشتر است.';
  static const stockAvailable = 'موجود';
  static const stockUnavailable = 'ناموجود';
  static const preOrder = 'پیش‌سفارش';
  static const retry = 'تلاش مجدد';
  static const mobile = 'موبایل';
  static const product = 'محصول';
  static const services = 'خدمات';
  static const electronics = 'الکترونیک';
  static const toman = AppStrings.tomanPersian;

  static String inStock(int count) =>
      '${AppStrings.persianDigits(count)} عدد موجود';

  /// Prefer Persian labels for known Home/API categories.
  static String postCategory(String category) {
    final key = category.trim().toLowerCase();
    return switch (key) {
      'product' || 'محصول' => product,
      'services' || 'service' || 'خدمات' => services,
      'mobile' || 'موبایل' => mobile,
      'electronics' || 'electronic' || 'الکترونیک' => electronics,
      'web development' || 'web_development' || 'توسعه وب' => 'توسعه وب',
      'electrical wiring' || 'electrical_wiring' || 'سیم‌کشی برق' =>
        'سیم‌کشی برق',
      'photography' || 'عکاسی' => 'عکاسی',
      'products' || 'محصولات' => 'محصولات',
      'fashion and clothing' || 'fashion' || 'مد و پوشاک' => 'مد و پوشاک',
      'other' || 'سایر' => 'سایر',
      'designing' || 'design' || 'طراحی' => 'طراحی',
      _ => category,
    };
  }
}
