enum PostMediaType { image, video, document }

/// Paths point to private app storage, independent of gallery/cache permissions.
class PostMedia {
  const PostMedia({
    required this.path,
    required this.name,
    required this.type,
    this.thumbnailPath,
    this.altText = '',
  });
  final String path;
  final String name;
  final PostMediaType type;
  final String? thumbnailPath;
  final String altText;

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'type': type.name,
    'thumbnailPath': thumbnailPath,
    'altText': altText,
  };
  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
    path: json['path'] as String,
    name: json['name'] as String,
    type: PostMediaType.values.byName(json['type'] as String),
    thumbnailPath: json['thumbnailPath'] as String?,
    altText: json['altText'] as String? ?? '',
  );
}
