import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class TagsDialog extends StatefulWidget {
  const TagsDialog({super.key, required this.initial});
  final List<String> initial;
  @override
  State<TagsDialog> createState() => _TagsDialogState();
}

class _TagsDialogState extends State<TagsDialog> {
  final _controller = TextEditingController();
  late final _draft = CreatePostCubit(
    initial: PostDraft(tags: List.unmodifiable(widget.initial)),
  );
  @override
  void dispose() {
    _draft.close();
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    _draft.addTags(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CreatePostCubit, PostDraft>(
    bloc: _draft,
    builder: (context, state) => PostDialog(
      title: CreatePostStrings.tagsKeywords,
      icon: AppIcons.tag,
      actions: PostDialogActions(
        onDone: () {
          _add();
          Navigator.of(context)
              .pop(List<String>.unmodifiable(_draft.state.tags));
        },
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppTextField(
              controller: _controller,
              label: CreatePostStrings.keywords,
              hint: CreatePostStrings.separateTags,
              onSubmitted: (_) => _add(),
              suffixIcon: IconButton(
                tooltip: CreatePostStrings.addTags,
                onPressed: _add,
                icon: const AppIcon(AppIcons.add),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _draft.state.tags)
                  InputChip(
                    label: Text('#$tag'),
                    deleteIcon: const AppIcon(AppIcons.close, size: 18),
                    onDeleted: () => _draft.removeTag(tag),
                  ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}
