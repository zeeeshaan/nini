class DisputeAttachment {
  const DisputeAttachment({
    required this.path,
    required this.name,
    required this.isImage,
  });
  final String path, name;
  final bool isImage;
  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'isImage': isImage,
  };
  factory DisputeAttachment.fromJson(Map<String, dynamic> json) =>
      DisputeAttachment(
        path: json['path'] as String,
        name: json['name'] as String,
        isImage: json['isImage'] as bool? ?? false,
      );
}
