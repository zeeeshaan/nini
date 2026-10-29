enum ChatAttachmentType { image, video, file, voice }

class ChatAttachment {
  const ChatAttachment({
    required this.path,
    required this.name,
    required this.type,
    required this.sizeBytes,
    this.thumbnailPath,
    this.duration,
  });
  final String path, name;
  final ChatAttachmentType type;
  final int sizeBytes;
  final String? thumbnailPath;
  final Duration? duration;
}
