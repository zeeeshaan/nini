/// Display identity supplied by the feed, separate from stored post metadata.
class PostSeller {
  const PostSeller({
    required this.id,
    required this.name,
    required this.avatarAsset,
    this.location = '',
    this.bio = '',
  });

  final String id, name, avatarAsset, location, bio;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarAsset': avatarAsset,
    'location': location,
    'bio': bio,
  };

  factory PostSeller.fromJson(Map<String, dynamic> json) => PostSeller(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarAsset: json['avatarAsset'] as String? ?? '',
    location: json['location'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
  );
}
