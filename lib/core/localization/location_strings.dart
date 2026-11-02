import 'package:nini/core/localization/app_strings.dart';

/// Persian labels for location settings and the Home permission prompt.
abstract final class LocationStrings {
  static const title = 'موقعیت‌های مکانی';
  static const label = 'عنوان';
  static const address = '…خیابان، لندن، NW1 6XE، بریتانیا';
  static const add = 'افزودن موقعیت';
  static const mapUnavailable = 'برای نمایش نقشه به اینترنت متصل شوید.';
  static const initialLabels = ['خانه', 'محل کار', 'موقعیت ۳', 'موقعیت ۴'];
  static const permissionQuestion =
      'آیا به «${AppStrings.appName}» اجازه می‌دهید به موقعیت مکانی این دستگاه دسترسی داشته باشد؟';
  static const permissionHint = 'مجوز نهایی در پنجره دستگاه شما تأیید می‌شود.';
  static const allowOnce = 'فقط این بار';
  static const allowWhileUsing = 'هنگام استفاده از برنامه';
  static const allowAlways = 'همیشه اجازه بده';
  static const doNotAllow = 'اجازه نده';
  static const permissionUnavailable =
      'درخواست دسترسی انجام نشد. دوباره تلاش کنید.';
}
