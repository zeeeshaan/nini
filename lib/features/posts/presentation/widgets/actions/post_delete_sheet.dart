import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/persian_feature/persian_feature.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/features/create_post/presentation/cubit/post_operation_cubit.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';

import '../../cubit/posts_cubit.dart';
import 'post_delete_actions.dart';

Future<bool> showPostDeleteConfirmation(
  BuildContext context,
  PostItem post, {
  Future<void> Function()? onBackendDelete,
}) async {
  if (onBackendDelete != null) {
    return await showPostDialog<bool>(
          context,
          BlocProvider(
            create: (_) => PostOperationCubit(),
            child: PersianFeature(
              child: PostDeleteSheet(
                post: post,
                onBackendDelete: onBackendDelete,
              ),
            ),
          ),
          isDismissible: false,
          enableDrag: false,
        ) ??
        false;
  }
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
  const PostDeleteSheet({super.key, required this.post, this.onBackendDelete});
  final PostItem post;
  final Future<void> Function()? onBackendDelete;
  @override
  Widget build(BuildContext context) {
    if (onBackendDelete != null) {
      return BlocBuilder<PostOperationCubit, PostOperationState>(
        builder: (context, state) => _sheet(
          context,
          busy: state.saving,
          deleting: state.saving,
          error: state.error,
          onDelete: () async {
            final operation = context.read<PostOperationCubit>();
            if (operation.state.saving) return;
            operation.beginSave();
            try {
              await onBackendDelete!();
              if (context.mounted) Navigator.of(context).pop(true);
            } catch (error) {
              if (!operation.isClosed)
                operation.fail(
                  error is PostApiException
                      ? error.message
                      : ProfilePostStrings.deleteFailed,
                );
            }
          },
        ),
      );
    }
    return BlocBuilder<PostsCubit, PostsState>(
      builder: (context, state) => _sheet(
        context,
        busy: state.isBusy,
        deleting: state.deletingPostId == post.id,
        error: state.deleteError,
        onDelete: () async {
          final deleted = await context.read<PostsCubit>().delete(post.id);
          if (deleted) {
            await WidgetsBinding.instance.endOfFrame;
            if (context.mounted) Navigator.of(context).pop(true);
          }
        },
      ),
    );
  }

  Widget _sheet(
    BuildContext context, {
    required bool busy,
    required bool deleting,
    required String? error,
    required VoidCallback onDelete,
  }) => PopScope(
    canPop: !busy,
    child: PostDialog(
      title: ProfilePostStrings.deletePostQuestion,
      actions: PostDeleteActions(
        busy: busy,
        deleting: deleting,
        onDelete: onDelete,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              post.title,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              ProfilePostStrings.deletePostHelp,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.inherit.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
