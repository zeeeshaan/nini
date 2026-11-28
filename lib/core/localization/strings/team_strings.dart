import '../app_string/app_string.dart';

abstract final class TeamStrings {
  static String requestProviders(int count) =>
      'Request selected providers (${AppStrings.persianDigits(count)})';
  static String peopleCount(int count) =>
      'People (${AppStrings.persianDigits(count)})';
  static String duration(Duration value) => value.inDays > 0
      ? '${AppStrings.persianDigits(value.inDays)} days'
      : '${AppStrings.persianDigits(value.inHours)} hours';
  static String selectedFileSize(int? bytes) => bytes == null
      ? 'Selected'
      : 'Selected · ${AppStrings.persianDigits((bytes / 1024).toStringAsFixed(1))} KB';

  static const selectMembers = 'Select team members';

  /// Shown until backend group/team messaging is available.
  static const messagingUnavailable = 'هنوز در دسترس نیست';

  static String done(int count) => '${AppStrings.done} ($count)';
  static String addMember(String name) => 'Add $name to team';
  static String removeMember(String name) => 'Remove $name from team';
}
