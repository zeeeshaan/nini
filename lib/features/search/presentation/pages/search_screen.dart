import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/features/search/presentation/cubit/search_cubit.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';

import 'search_view.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.active = true,
    this.publishedServiceId,
    this.onPostSelected,
    this.emptyStateTextAlign = TextAlign.right,
  });

  final bool active;
  final TextAlign emptyStateTextAlign;
  final String? publishedServiceId;
  final void Function(PostItem post, PostSeller seller)? onPostSelected;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repository = context.read<ApiPostsRepository?>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SearchCubit(repository)),
        if (repository != null)
          BlocProvider<BackendPostsCubit>(
            create: (_) => BackendPostsCubit(
              (page) => repository.search(query: '', page: page),
              repository: repository,
              syncPublicWithdrawals: true,
            ),
          ),
      ],
      child: SearchView(
        active: widget.active,
        publishedServiceId: widget.publishedServiceId,
        onPostSelected: widget.onPostSelected,
        emptyStateTextAlign: widget.emptyStateTextAlign,
      ),
    );
  }
}
