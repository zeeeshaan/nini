import '../app_string/app_string.dart';

/// Persian interface text for the notification preview and its accessibility labels.
abstract final class NotificationStrings {
  static const title = 'اعلان‌ها';
  static const search = 'جستجو در اعلان‌ها';
  static const clearSearch = 'پاک کردن جستجو';
  static const noResults = 'اعلانی با این عبارت پیدا نشد.';
  static const empty = 'هنوز اعلانی ندارید.';
  static const now = 'اکنون';
  static String minutesAgo(int count) =>
      '${AppStrings.persianDigits(count)} دقیقه پیش';
  static String hoursAgo(int count) =>
      '${AppStrings.persianDigits(count)} ساعت پیش';
  static String daysAgo(int count) =>
      '${AppStrings.persianDigits(count)} روز پیش';
  static const minuteAgo = '۱ دقیقه پیش';
  static const brand = "های‌ورک";
  static const newOrder = 'یک سفارش جدید دارید.';
  static const saleTitle = 'فروش ویژه شروع شد';
  static const saleMessage =
      'فروش ویژه آغاز شده است. پیشنهادهای تازه را از دست ندهید.';
}
