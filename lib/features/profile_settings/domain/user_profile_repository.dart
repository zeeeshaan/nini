import 'dart:typed_data';

import 'user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> load();
  Future<UserProfile> save(UserProfile profile, {Uint8List? photo});
}

/// A safe, actionable profile error that can be shown by the editor.
class UserProfileException implements Exception {
  const UserProfileException(
    this.message, {
    this.confirmedProfile,
    this.photoUploadUnavailable = false,
  });
  final String message;
  final UserProfile? confirmedProfile;
  final bool photoUploadUnavailable;
}
