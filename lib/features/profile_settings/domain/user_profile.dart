import 'package:nini/shared/models/post/post_seller.dart';

class UserProfile {
  const UserProfile({
    this.id = '',
    this.firstName = '',
    this.lastName = '',
    this.nationality = '',
    this.username = '',
    this.email = '',
    this.birthDate,
    this.gender = '',
    this.bio = '',
    this.businessType = '',
    this.city = '',
    this.avatarPath = defaultAvatar,
  });

  static const defaultAvatar = '';

  final String id, city;
  final String firstName, lastName, nationality, username, email, gender;
  final String bio, businessType, avatarPath;
  final DateTime? birthDate;

  String get displayName {
    final name = [firstName, lastName]
        .where((value) => value.trim().isNotEmpty)
        .map((value) => value.trim())
        .join(' ');
    return name;
  }

  PostSeller get seller => PostSeller(
    id: id,
    username: username,
    name: displayName.isEmpty ? username : displayName,
    avatarAsset: avatarPath,
    bio: bio,
    location: city,
  );

  UserProfile withAvatar(String path) => UserProfile(
    id: id,
    city: city,
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
    'id': id,
    'city': city,
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
      id: json['id'] as String? ?? '',
      city: json['city'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      gender: json['gender'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      // Older local profiles stored the bundled placeholder as their photo.
      // Real uploaded images are durable file paths and stay unchanged.
      avatarPath: avatar.startsWith('assets/') ? defaultAvatar : avatar,
    );
  }
}
