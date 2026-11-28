import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/features/create_post/models/gallery_attachment.dart';
import 'package:hywork/features/create_post/screens/create_post_gallery_screen.dart';

import '../../cubit/post_editor_media_cubit.dart';
import 'post_editor_alt_text_fields.dart';
import '../media/post_editor_media_grid.dart';

class PostEditorMediaSection extends StatelessWidget {
  const PostEditorMediaSection({super.key, this.backend = false});
  final bool backend;
  Future<void> _pick(BuildContext context, {bool replace = false}) async {
    final selected = await Navigator.of(context).push<List<GalleryAttachment>>(
      MaterialPageRoute(
        builder: (pickerContext) => CreatePostGalleryScreen(
          prepareForPost: backend,
          nextLabel: ProfilePostStrings.next,
          onNext: (items) => Navigator.of(pickerContext).pop(items),
        ),
      ),
    );
    if (!context.mounted || selected == null || selected.isEmpty) return;
    final media = context.read<PostEditorMediaCubit>();
    if (replace) {
      media.replace(selected);
    } else {
      media.add(selected);
    }
  }

  @override
  Widget build(BuildContext context) => FormField<int>(
    validator: (_) => context.read<PostEditorMediaCubit>().state.count == 0
        ? ProfilePostStrings.mediaRequired
        : null,
    builder: (field) =>
        BlocConsumer<PostEditorMediaCubit, PostEditorMediaState>(
          listener: (_, state) => field.didChange(state.count),
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ProfilePostStrings.media,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _pick(context, replace: true),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text(
                      ProfilePostStrings.replaceMedia,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _pick(context),
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      ProfilePostStrings.addMedia,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              PostEditorMediaGrid(state: state),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    field.errorText!,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.inherit.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              PostEditorAltTextFields(media: state),
            ],
          ),
        ),
  );
}
