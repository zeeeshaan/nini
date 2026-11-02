import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/shared/models/post/post_item.dart';

import '../../cubit/posts_cubit.dart';
import '../post_delete_actions/post_delete_actions.dart';

Future<bool> showPostDeleteConfirmation(
  BuildContext context,
  PostItem post,
) async {
  final posts = context.read<PostsCubit>()..clearDeleteError();
  return await showPostDialog<bool>(
        context,
        BlocProvider.value(
          value: posts,
          child: PersianFeature(child: PostDeleteSheet(post: post)),
        ),
        isDismissible: false,
        enableDrag: false,
      ) ??
      false;
}

class PostDeleteSheet extends StatelessWidget {
  const PostDeleteSheet({super.key, required this.post});
  final PostItem post;
  @override
  Widget build(BuildContext context) => BlocBuilder<PostsCubit, PostsState>(
    builder: (context, state) => PopScope(
      canPop: !state.isBusy,
      child: PostDialog(
        title: ProfilePostStrings.deletePostQuestion,
        actions: PostDeleteActions(
          busy: state.isBusy,
          deleting: state.deletingPostId == post.id,
          onDelete: () async {
            final deleted = await context.read<PostsCubit>().delete(post.id);
            if (deleted) {
              await WidgetsBinding.instance.endOfFrame;
              if (context.mounted) Navigator.of(context).pop(true);
            }
          },
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                post.title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                ProfilePostStrings.deletePostHelp,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              if (state.deleteError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.deleteError!,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
