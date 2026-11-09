import 'dart:typed_data';

import 'user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> load();
  Future<UserProfile> save(UserProfile profile, {Uint8List? photo});
}
