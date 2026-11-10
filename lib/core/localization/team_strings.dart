import 'app_strings.dart';

abstract final class TeamStrings {
  static const selectMembers = 'Select team members';

  static String done(int count) => '${AppStrings.done} ($count)';
  static String addMember(String name) => 'Add $name to team';
  static String removeMember(String name) => 'Remove $name from team';
}
