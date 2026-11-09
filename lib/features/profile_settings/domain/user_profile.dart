import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/models/local_identity.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class UserProfile {
  const UserProfile({
    this.firstName = AppStrings.sellerName,
    this.lastName = '',
    this.nationality = '',
    this.username = '',
    this.email = '',
    this.birthDate,
    this.gender = '',
    this.bio = AppStrings.sellerBio,
    this.businessType = AppStrings.shopAndStore,
    this.avatarPath = defaultAvatar,
  });

  static const defaultAvatar = '';

  final String firstName, lastName, nationality, username, email, gender;
  final String bio, businessType, avatarPath;
  final DateTime? birthDate;

  String get displayName {
    final name = [firstName, lastName]
        .where((value) => value.trim().isNotEmpty)
        .map((value) => value.trim())
        .join(' ');
    return name.isEmpty ? AppStrings.sellerName : name;
  }

  PostSeller get seller => PostSeller(
    id: localProfileId,
    name: displayName,
    avatarAsset: avatarPath,
    bio: bio,
  );

  UserProfile withAvatar(String path) => UserProfile(
    firstName: firstName,
    lastName: lastName,
    nationality: nationality,
    username: username,
    email: email,
    birthDate: birthDate,
    gender: gender,
    bio: bio,
    businessType: businessType,
    avatarPath: path,
  );

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'nationality': nationality,
    'username': username,
    'email': email,
    'birthDate': birthDate?.toIso8601String(),
    'gender': gender,
    'bio': bio,
    'businessType': businessType,
    'avatarPath': avatarPath,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatarPath'] as String? ?? defaultAvatar;
    return UserProfile(
      firstName: json['firstName'] as String? ?? AppStrings.sellerName,
      lastName: json['lastName'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      gender: json['gender'] as String? ?? '',
      bio: json['bio'] as String? ?? AppStrings.sellerBio,
      businessType: json['businessType'] as String? ?? AppStrings.shopAndStore,
      // Older local profiles stored the bundled placeholder as their photo.
      // Real uploaded images are durable file paths and stay unchanged.
      avatarPath: avatar.startsWith('assets/') ? defaultAvatar : avatar,
    );
  }
}
