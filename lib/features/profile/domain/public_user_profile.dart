import 'package:nini/shared/models/post/post_seller.dart';

class PublicUserProfile {
  const PublicUserProfile({
    required this.seller,
    this.followersCount,
    this.followingCount,
    this.postsCount,
    this.isMe,
    this.isFollowing,
  });

  final PostSeller seller;
  final int? followersCount, followingCount, postsCount;
  final bool? isMe, isFollowing;

  static String? normalizeUsername(String value) {
    final username = value.trim().replaceFirst(RegExp(r'^@'), '');
    return RegExp(r'^[a-z0-9_.]{3,30}$').hasMatch(username) ? username : null;
  }

  factory PublicUserProfile.fromJson(
    Map<String, dynamic> json, {
    required String username,
    String? expectedUserId,
  }) {
    String text(String key) {
      final value = json[key];
      if (value == null) return '';
      if (value is String) return value;
      throw const FormatException('Invalid public profile field.');
    }

    int? count(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is int && value >= 0) return value;
      throw const FormatException('Invalid public profile count.');
    }

    bool? flag(String key) {
      final value = json[key];
      if (value == null || value is bool) return value as bool?;
      throw const FormatException('Invalid public profile relationship.');
    }

    final id = text('id');
    final returnedUsername = text('username');
    if (id.trim().isEmpty ||
        returnedUsername != username ||
        (expectedUserId != null &&
            expectedUserId.isNotEmpty &&
            expectedUserId != id)) {
      throw const FormatException('Public profile identity was not confirmed.');
    }
    final avatar = text('avatarUrl');
    final uri = Uri.tryParse(avatar);
    final validAvatar =
        uri != null &&
        uri.host.isNotEmpty &&
        const ['http', 'https'].contains(uri.scheme);
    return PublicUserProfile(
      seller: PostSeller(
        id: id,
        username: returnedUsername,
        name: text('name'),
        avatarAsset: validAvatar ? avatar : '',
        bio: text('bio'),
        location: text('city'),
      ),
      followersCount: count('followersCount'),
      followingCount: count('followingCount'),
      postsCount: count('postsCount'),
      isMe: flag('isMe'),
      isFollowing: flag('isFollowing'),
    );
  }
}
