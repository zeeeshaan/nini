import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/shared/models/post/post_item.dart';

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
              .where((p) => p.title.toLowerCase().contains(query))
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
                                return ProfilePostCard(
                                  post: PostItem(
                                    id: post.id,
                                    imageAsset: '',
                                    title: post.title,
                                    category: label,
                                    stockCount: 0,
                                    price: toman,
                                    originalPrice: '',
                                  ),
                                  onTap: null,
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
