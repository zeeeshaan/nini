import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:hywork/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/features/posts/presentation/pages/edit_post_screen.dart';
import 'package:hywork/features/posts/presentation/widgets/actions/post_owner_actions_sheet.dart';
import 'package:hywork/features/posts/presentation/widgets/actions/post_delete_sheet.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:hywork/features/create_post/presentation/cubit/post_operation_cubit.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

import 'dart:async';

import '../cubit/settings_query_cubit.dart';
import '../widgets/common/settings_page.dart';
import '../widgets/common/settings_posts_content.dart';
import '../widgets/common/settings_posts_grid.dart';
import '../widgets/common/settings_search_field.dart';
import '../widgets/posts/settings_posts_list.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key, this.initialQuery = '', this.tag});
  final String initialQuery;
  final String? tag;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SettingsQueryCubit(initialQuery),
    child: SettingsPage(
      title: ProfileSettingsStrings.posts,
      child: Column(
        children: [
          const SettingsSearchField(),
          if (tag == null)
            const Expanded(child: _ServerPosts())
          else
            Expanded(
              child: SettingsPostsContent(
                builder: (context, posts) =>
                    SettingsPostsList(posts: posts, tag: tag),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ServerPosts extends StatefulWidget {
  const _ServerPosts();
  @override
  State<_ServerPosts> createState() => _ServerPostsState();
}

class _ServerPostsState extends State<_ServerPosts> {
  late Future<MyPostsPage> _loading;
  int _page = 1;
  final _operation = PostOperationCubit();

  @override
  void dispose() {
    _operation.close();
    super.dispose();
  }

  Future<void> _manage(MyServerPost post, PostItem card) async {
    if (_operation.state.saving) return;
    final editable = const {
      'published',
      'pending_review',
      'changes_requested',
    }.contains(post.status);
    final action = await showPostOwnerActions(
      context,
      allowEdit: editable,
      allowResubmit: post.status == 'changes_requested',
    );
    if (!mounted || action == null) return;
    final repository = context.read<ApiPostsRepository>();
    switch (action) {
      case PostOwnerAction.edit:
        final updated = await Navigator.of(context).push<PostItem>(
          MaterialPageRoute(
            builder: (_) => BackendEditPostScreen(postId: post.id),
          ),
        );
        if (mounted && updated != null) _load(_page);
      case PostOwnerAction.delete:
        final deleted = await showPostDeleteConfirmation(
          context,
          card,
          onBackendDelete: () => repository.deleteOwnedPost(post),
        );
        if (!mounted || !deleted) return;
        final feed = context.read<FeedCubit?>();
        final own = context.read<OwnPostsCubit?>();
        if (feed != null) unawaited(feed.refreshFromServer());
        if (own != null) unawaited(own.refresh());
        _load(_page);
        AppToast.success(context, 'Post deleted.');
      case PostOwnerAction.resubmit:
        if (_operation.state.saving) return;
        _operation.beginSave();
        try {
          await repository.resubmitOwnedPost(post);
          if (!mounted) return;
          _load(_page);
          AppToast.success(context, 'Post updated successfully.');
        } catch (error) {
          if (mounted)
            AppToast.error(
              context,
              error is PostApiException
                  ? error.message
                  : 'Could not resubmit the post.',
            );
        } finally {
          if (!_operation.isClosed) _operation.retry();
        }
    }
  }

  String? _imageUrl(Object? value) {
    if (value is! String || value.trim() != value) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _loading = context.read<ApiPostsRepository>().loadMine();
  }

  void _load(int page) => setState(() {
    _page = page;
    _loading = context.read<ApiPostsRepository>().loadMine(page: page);
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<MyPostsPage>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done &&
          !snapshot.hasData) {
        return const SettingsPostsGrid(
          loading: true,
          showStatus: true,
          gridDirection: TextDirection.rtl,
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return Center(
          child: TextButton(
            onPressed: () => _load(_page),
            child: const Text('Unable to load My Posts. Tap to retry.'),
          ),
        );
      }
      final result = snapshot.data!;
      return BlocBuilder<SettingsQueryCubit, String>(
        builder: (context, query) {
          final posts = result.items
              .where(
                (p) =>
                    !context.read<ApiPostsRepository>().isDeleted(p.id) &&
                    p.title.toLowerCase().contains(query),
              )
              .toList();
          return Column(
            children: [
              if (snapshot.connectionState != ConnectionState.done)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: posts.isEmpty
                    ? const Center(child: Text('No posts on this page.'))
                    : AppResponsiveBuilder(
                        builder: (context, responsive) {
                          final textScale =
                              (MediaQuery.textScalerOf(context).scale(14) / 14)
                                  .clamp(1.0, double.infinity);
                          final columns = (responsive.width / (110 * textScale))
                              .floor()
                              .clamp(1, responsive.gridColumns.clamp(1, 3));
                          final width =
                              (responsive.width - (columns - 1) * 2) / columns;
                          final scale = width / ProfilePostCard.referenceWidth;
                          final detailsHeight =
                              ProfilePostCard.detailsHeightFor(context, scale);
                          return Directionality(
                            textDirection: TextDirection.rtl,
                            child: GridView.builder(
                              itemCount: posts.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 2,
                                    mainAxisExtent: width + detailsHeight,
                                  ),
                              itemBuilder: (context, index) {
                                final post = posts[index];
                                final thumbnail = _imageUrl(
                                  post.data['thumbnailUrl'],
                                );
                                final original = _imageUrl(post.data['image']);
                                final preview =
                                    thumbnail ??
                                    original ??
                                    _imageUrl(post.image);
                                final price =
                                    post.data['finalPrice'] ??
                                    post.data['price'];
                                final toman = price is int
                                    ? (price % 10 == 0
                                          ? '${price ~/ 10}'
                                          : '${price ~/ 10}.${price % 10}')
                                    : '';
                                final category = post.data['category'];
                                final label =
                                    category is Map &&
                                        category['label'] is String
                                    ? category['label'] as String
                                    : '';
                                final card = PostItem(
                                  id: post.id,
                                  imageAsset: '',
                                  title: post.title,
                                  category: label,
                                  stockCount: 0,
                                  price: toman,
                                  originalPrice: '',
                                );
                                return ProfilePostCard(
                                  post: card,
                                  onTap: () => _manage(post, card),
                                  detailsHeight: detailsHeight,
                                  contentScale: scale,
                                  categoryLabel: label,
                                  showStock: false,
                                  imageOverride: preview != null
                                      ? Image.network(
                                          preview,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              thumbnail != null &&
                                                  original != null &&
                                                  thumbnail != original
                                              ? Image.network(
                                                  original,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      const Icon(
                                                        Icons.image_outlined,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.image_outlined,
                                                ),
                                        )
                                      : const Icon(Icons.image_outlined),
                                  statusLabel: Tooltip(
                                    message: [
                                      post.status.replaceAll('_', ' '),
                                      if (post.reviewNote != null &&
                                          post.reviewNote!.isNotEmpty)
                                        post.reviewNote!,
                                      if (post.rejectionReason != null &&
                                          post.rejectionReason!.isNotEmpty)
                                        post.rejectionReason!.replaceAll(
                                          '_',
                                          ' ',
                                        ),
                                    ].join(' · '),
                                    child: Text(
                                      post.status.replaceAll('_', ' '),
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: result.page > 1
                        ? () => _load(result.page - 1)
                        : null,
                    child: const Text('Previous'),
                  ),
                  Text('Page ${result.page}'),
                  TextButton(
                    onPressed: result.page * result.limit < result.total
                        ? () => _load(result.page + 1)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
