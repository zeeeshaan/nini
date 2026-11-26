import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';

/// Media update request, separate from the editable post information.
/// Retained paths reference existing media on this post; adapters must validate
/// those references against the stored post. Additions are newly picked files.
/// An API adapter can map existing references to its server media identifiers.
class PostMediaChanges {
  PostMediaChanges({
    required Iterable<String> retainedPaths,
    required Iterable<GalleryAttachment> additions,
  }) : retainedPaths = List.unmodifiable(retainedPaths),
       additions = List.unmodifiable(additions);
  final List<String> retainedPaths;
  final List<GalleryAttachment> additions;
}
