import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/create_post/models/gallery_attachment.dart';
import 'package:hywork/shared/models/post/post_media.dart';

import 'post_editor_media_state.dart';

export 'post_editor_media_state.dart';

/// Keeps unsaved media selections independent of platform storage and the draft.
class PostEditorMediaCubit extends Cubit<PostEditorMediaState> {
  PostEditorMediaCubit(List<PostMedia> media)
    : super(PostEditorMediaState(retained: media));
  void add(List<GalleryAttachment> attachments) {
    final additions = {for (final item in state.additions) item.id: item};
    for (final item in attachments) {
      additions[item.id] = item;
    }
    emit(
      PostEditorMediaState(
        retained: state.retained,
        additions: additions.values,
      ),
    );
  }

  void replace(List<GalleryAttachment> attachments) =>
      emit(PostEditorMediaState(retained: const [], additions: attachments));
  void removeExisting(String path) => emit(
    PostEditorMediaState(
      retained: state.retained.where((item) => item.path != path),
      additions: state.additions,
    ),
  );
  void removeAddition(String id) => emit(
    PostEditorMediaState(
      retained: state.retained,
      additions: state.additions.where((item) => item.id != id),
    ),
  );
}
