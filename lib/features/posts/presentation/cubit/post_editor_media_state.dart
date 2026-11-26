import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
import 'package:hywork/shared/models/post/post_media.dart';

import '../../domain/models/post_media_changes.dart';

class PostEditorMediaState {
  PostEditorMediaState({
    required Iterable<PostMedia> retained,
    Iterable<GalleryAttachment> additions = const [],
  }) : retained = List.unmodifiable(retained),
       additions = List.unmodifiable(additions);
  final List<PostMedia> retained;
  final List<GalleryAttachment> additions;
  int get count => retained.length + additions.length;
  PostMediaChanges get changes => PostMediaChanges(
    retainedPaths: retained.map((item) => item.path),
    additions: additions,
  );
}
