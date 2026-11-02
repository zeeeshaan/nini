import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/post_editor_media_cubit.dart';
import '../post_editor_media_tile/post_editor_media_tile.dart';

class PostEditorMediaGrid extends StatelessWidget {
  const PostEditorMediaGrid({super.key, required this.state});
  final PostEditorMediaState state;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    itemCount: state.count,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemBuilder: (context, index) {
      final editor = context.read<PostEditorMediaCubit>();
      if (index < state.retained.length) {
        final media = state.retained[index];
        return PostEditorMediaTile.existing(
          key: ValueKey(media.path),
          media: media,
          onRemove: () => editor.removeExisting(media.path),
        );
      }
      final attachment = state.additions[index - state.retained.length];
      return PostEditorMediaTile.picked(
        key: ValueKey(attachment.id),
        attachment: attachment,
        onRemove: () => editor.removeAddition(attachment.id),
      );
    },
  );
}
