import '../../domain/user_profile.dart';

class UserProfileState {
  const UserProfileState({
    this.profile = const UserProfile(),
    this.loading = true,
    this.saving = false,
    this.loadFailed = false,
    this.saveFailed = false,
  });

  final UserProfile profile;
  final bool loading, saving, loadFailed, saveFailed;
}
