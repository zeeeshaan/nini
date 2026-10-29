import 'package:nini/features/chat/domain/models/chat_attachment.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';

abstract class ChatMediaStore {
  Future<List<ChatAttachment>> prepare(List<GalleryAttachment> selected);
  Future<ChatAttachment> prepareVoice(String path, Duration duration);
  Future<void> discard(Iterable<ChatAttachment> attachments);
}
