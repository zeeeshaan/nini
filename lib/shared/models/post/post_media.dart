enum PostMediaType { image, video, document }

enum PostMediaSource { local, asset }

/// Uploaded files use private app storage; bundled profile samples use assets.
class PostMedia {
  const PostMedia({
    required this.path,
    required this.name,
    required this.type,
    this.thumbnailPath,
    this.altText = '',
    this.source = PostMediaSource.local,
  });
  final String path;
  final String name;
  final PostMediaType type;
  final PostMediaSource source;
  final String? thumbnailPath;
  final String altText;

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'type': type.name,
    'source': source.name,
    'thumbnailPath': thumbnailPath,
    'altText': altText,
  };
  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
    path: json['path'] as String,
    name: json['name'] as String,
    type: PostMediaType.values.byName(json['type'] as String),
    source: json['source'] == 'asset'
        ? PostMediaSource.asset
        : PostMediaSource.local,
    thumbnailPath: json['thumbnailPath'] as String?,
    altText: json['altText'] as String? ?? '',
  );
}
