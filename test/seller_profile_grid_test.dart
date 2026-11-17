import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_grid.dart';
import 'package:nini/features/profile/presentation/widgets/seller/seller_post_grid.dart';
import 'package:nini/shared/models/post/post_item.dart';

class _Posts extends Fake implements PostsRepository {
  _Posts(this.posts);
  final List<PostItem> posts;
  @override
  Future<List<PostItem>> load() async => posts;
}

class _Categories extends Fake implements ProfileCategoriesRepository {}

final _posts = List.generate(
  3,
  (index) => PostItem(
    id: 'post-$index',
    imageAsset: 'assets/img1.png',
    title: 'Post $index',
    category: 'Product',
    stockCount: 2,
    price: '12000',
    originalPrice: '13000',
    details: const PostDetails(unit: PostUnit.piece),
  ),
);

Widget _host(Widget grid, {double width = 390, double scale = 1}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(child: grid),
          ),
        ),
      ),
    );

void main() {
  for (final scenario in [
    (width: 390.0, scale: 1.0),
    (width: 240.0, scale: 1.0),
    (width: 390.0, scale: 2.0),
  ]) {
    testWidgets('other-user grid matches own profile at $scenario', (
      tester,
    ) async {
      final posts = PostsCubit(_Posts(_posts));
      await posts.load();
      final categories = ProfileCategoriesCubit(_Categories());
      addTearDown(posts.close);
      addTearDown(categories.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: posts),
            BlocProvider.value(value: categories),
          ],
          child: _host(
            ProfilePostGrid(onPostTap: (_) {}),
            width: scenario.width,
            scale: scenario.scale,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ownDelegate =
          tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      final ownCard = tester.widget<ProfilePostCard>(
        find.byType(ProfilePostCard).first,
      );
      final ownSize = tester.getSize(find.byType(ProfilePostCard).first);
      PostItem? selected;
      await tester.pumpWidget(
        _host(
          SellerPostGrid(posts: _posts, onPostTap: (post) => selected = post),
          width: scenario.width,
          scale: scenario.scale,
        ),
      );
      await tester.pumpAndSettle();
      final delegate =
          tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      final card = tester.widget<ProfilePostCard>(
        find.byType(ProfilePostCard).first,
      );
      expect(delegate.crossAxisCount, ownDelegate.crossAxisCount);
      expect(delegate.crossAxisSpacing, ownDelegate.crossAxisSpacing);
      expect(delegate.mainAxisSpacing, ownDelegate.mainAxisSpacing);
      expect(delegate.mainAxisExtent, ownDelegate.mainAxisExtent);
      expect(card.contentScale, ownCard.contentScale);
      expect(card.detailsHeight, ownCard.detailsHeight);
      expect(card.showStock, isTrue);
      final stock = find.descendant(
        of: find.byType(ProfilePostCard).first,
        matching: find.byType(Visibility),
      );
      expect(tester.widget<Visibility>(stock).visible, isTrue);
      expect(tester.getSize(find.byType(ProfilePostCard).first), ownSize);
      final first = tester.getRect(find.byType(ProfilePostCard).first);
      final grid = tester.getRect(find.byType(GridView));
      expect(first.right, closeTo(grid.right, .1));
      expect(find.text('Post 0'), findsOneWidget);
      expect(find.text('12,000'), findsWidgets);
      expect(find.text('13,000'), findsWidgets);
      await tester.tap(find.byType(ProfilePostCard).first);
      expect(selected, same(_posts.first));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('service posts do not show stock even with a positive count', (
    tester,
  ) async {
    final service = PostItem.fromJson({
      ..._posts.first.toJson(),
      'category': 'Plumbing',
      'metadata': {'postType': 'services', 'warehouseStock': '2'},
    });
    await tester.pumpWidget(
      _host(SellerPostGrid(posts: [service], onPostTap: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(service.isService, isTrue);
    expect(tester.widget<Visibility>(find.byType(Visibility)).visible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty other-user profile keeps the current empty message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(SellerPostGrid(posts: const [], onPostTap: (_) {})),
    );
    expect(find.byType(ProfilePostCard), findsNothing);
    expect(find.text(AppStrings.noSellerPosts), findsOneWidget);
  });
}
