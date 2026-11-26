import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
import 'package:hywork/shared/models/post/post_media.dart';

/// Maps existing post media into create-screen attachments for edit mode.
List<GalleryAttachment> attachmentsFromPostMedia(List<PostMedia> media) {
  return [
    for (final item in media)
      if (item.path.isNotEmpty)
        GalleryAttachment.fromRemote(
          url: item.thumbnailPath?.isNotEmpty == true
              ? item.thumbnailPath!
              : item.path,
          id: item.path,
        ),
  ];
}
