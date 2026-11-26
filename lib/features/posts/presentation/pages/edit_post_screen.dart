import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/persian_feature/persian_feature.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/features/create_post/data/api_categories_repository.dart';
import 'package:hywork/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:hywork/features/create_post/presentation/cubit/post_categories_cubit.dart';
import 'package:hywork/features/create_post/presentation/pages/create_post_details_screen.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/features/posts/presentation/helpers/post_draft_mapper.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

/// Loads the owner's canonical post, then opens the create-style editor.
class BackendEditPostScreen extends StatefulWidget {
  const BackendEditPostScreen({super.key, required this.postId});
  final String postId;

  @override
  State<BackendEditPostScreen> createState() => _BackendEditPostScreenState();
}

class _BackendEditPostScreenState extends State<BackendEditPostScreen> {
  late final Future<MyServerPost> _post;

  @override
  void initState() {
    super.initState();
    _post = context.read<ApiPostsRepository>().loadEditablePost(widget.postId);
  }

  PreferredSizeWidget _editPostAppBar(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    title: const Align(
      alignment: Alignment.centerRight,
      child: Text(
        ProfilePostStrings.editPost,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      ),
    ),
    actions: [
      IconButton(
        tooltip: ProfilePostStrings.back,
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const AppIcon(AppIcons.backRight, size: 18),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<MyServerPost>(
    future: _post,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return Scaffold(
          appBar: _editPostAppBar(context),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return Scaffold(
          appBar: _editPostAppBar(context),
          body: const Center(
            child: Text('Unable to load this post for editing.'),
          ),
        );
      }
      try {
        final serverPost = snapshot.data!;
        final post = backendPostFromJson(serverPost.data);
        return EditPostScreen(post: post, backendPost: serverPost);
      } catch (_) {
        return Scaffold(
          appBar: _editPostAppBar(context),
          body: const Center(
            child: Text('Unable to load this post for editing.'),
          ),
        );
      }
    },
  );
}

/// Opens the same create-post details UI, prefilled for editing.
class EditPostScreen extends StatelessWidget {
  const EditPostScreen({super.key, required this.post, this.backendPost});
  final PostItem post;
  final MyServerPost? backendPost;

  @override
  Widget build(BuildContext context) {
    final draft = backendPost == null
        ? postDraftFromPost(post)
        : postDraftFromBackend(post, backendPost!.data);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CreatePostCubit(initial: draft)),
        BlocProvider(
          create: (context) => PostCategoriesCubit(
            ApiCategoriesRepository(
              context.read<ApiPostsRepository>().client,
            ),
          )..load(),
        ),
      ],
      child: PersianFeature(
        child: CreatePostDetailsScreen(
          editPost: post,
          backendPost: backendPost,
        ),
      ),
    );
  }
}
