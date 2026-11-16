import '../app_string/app_string.dart';

abstract final class TeamStrings {
  static String requestProviders(int count) =>
      'درخواست از متخصصان انتخاب‌شده (${AppStrings.persianDigits(count)})';
  static String peopleCount(int count) =>
      'اعضا (${AppStrings.persianDigits(count)})';
  static String duration(Duration value) => value.inDays > 0
      ? '${AppStrings.persianDigits(value.inDays)} روز'
      : '${AppStrings.persianDigits(value.inHours)} ساعت';
  static String selectedFileSize(int? bytes) => bytes == null
      ? 'انتخاب‌شده'
      : 'انتخاب‌شده · ${AppStrings.persianDigits((bytes / 1024).toStringAsFixed(1))} کیلوبایت';

  static const selectMembers = "انتخاب اعضای تیم";

  static String done(int count) =>
      '${AppStrings.done} (${AppStrings.persianDigits(count)})';
  static String addMember(String name) => 'افزودن $name به تیم';
  static String removeMember(String name) => 'حذف $name از تیم';
}
