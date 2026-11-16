import 'package:nini/core/localization/app_string/app_string.dart';

/// Persian interface labels for location settings and the Home permission prompt.
abstract final class LocationStrings {
  static const title = 'موقعیت‌های مکانی';
  static const label = 'عنوان';
  static const address = '…خیابان، لندن، NW1 6XE، بریتانیا';
  static const add = 'افزودن موقعیت';
  static const mapUnavailable = 'برای نمایش نقشه به اینترنت متصل شوید.';
  static const initialLabels = ['خانه', 'محل کار', 'موقعیت ۳', 'موقعیت ۴'];
  static const permissionQuestion =
      'به ${AppStrings.appName} اجازه دسترسی به موقعیت این دستگاه داده شود؟';
  static const permissionHint = "مجوز را در پنجره دستگاه تأیید کنید.";
  static const allowOnce = "اجازه برای یک بار";
  static const allowWhileUsing = "اجازه هنگام استفاده از برنامه";
  static const allowAlways = "اجازه همیشه";
  static const doNotAllow = "اجازه نده";
  static const permissionUnavailable =
      "درخواست دسترسی به موقعیت انجام نشد. دوباره تلاش کنید.";
}
