/// Display identity supplied by the feed, separate from stored post metadata.
class PostSeller {
  const PostSeller({
    required this.id,
    required this.name,
    required this.avatarAsset,
    this.location = '',
    this.bio = '',
    this.username = '',
  });

  final String id, name, avatarAsset, location, bio, username;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarAsset': avatarAsset,
    'location': location,
    'bio': bio,
    'username': username,
  };

  factory PostSeller.fromJson(Map<String, dynamic> json) => PostSeller(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarAsset: json['avatarAsset'] as String? ?? '',
    location: json['location'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    username: json['username'] as String? ?? '',
  );
}
