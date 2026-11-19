import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/features/search/data/search_catalog.dart';
import 'package:nini/features/search/presentation/widgets/results/search_result_card.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/features/posts/presentation/widgets/media/post_media_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/home/presentation/widgets/published/home_post_media_slider.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';

PostItem _post({
  String title = 'Wireless\nBluetooth Headphones',
  bool rating = true,
  bool service = false,
  bool published = false,
  bool discounted = true,
}) => PostItem.fromJson({
  'id': 'layout-post',
  'imageAsset': 'assets/img1.png',
  'title': title,
  'category': service ? 'Services' : 'Mobile',
  'stockCount': 2,
  'price': '12000',
  'originalPrice': discounted ? '13000' : '',
  'publishedAt': published ? DateTime(2026).toIso8601String() : null,
  'metadata': {
    'unit': 'meter',
    'warehouseStock': '2',
    'postType': service ? 'services' : 'product',
    if (rating) 'rating': 5,
  },
});

Widget _app({
  bool search = false,
  double width = 200,
  double textScale = 1,
  String title = 'Wireless\nBluetooth Headphones',
  bool rating = true,
  bool service = false,
  bool discounted = true,
  VoidCallback? onTap,
}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Builder(
            builder: (context) {
              final scale = width / ProfilePostCard.referenceWidth;
              final height = ProfilePostCard.detailsHeightFor(context, scale);
              final post = _post(
                title: title,
                rating: rating,
                service: service,
                discounted: discounted,
              );
              final card = search
                  ? SearchResultCard(
                      post: post,
                      contentScale: scale,
                      detailsHeight: height,
                      onTap: onTap,
                    )
                  : ProfilePostCard(
                      post: post,
                      contentScale: scale,
                      detailsHeight: height,
                      onTap: onTap,
                    );
              return RepaintBoundary(
                key: const ValueKey('grid-card-preview'),
                child: card,
              );
            },
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('small media prefers the real thumbnail and falls back once', (
    tester,
  ) async {
    const media = PostMedia(
      path: 'https://example.test/original.jpg',
      thumbnailPath: 'https://example.test/thumb.jpg',
      name: 'image',
      type: PostMediaType.image,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 120,
          height: 120,
          child: PostMediaView(
            media: media,
            preferThumbnail: true,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
    final first = tester.widget<Image>(find.byType(Image).first);
    expect((first.image as NetworkImage).url, media.thumbnailPath);
    final context = tester.element(find.byType(PostMediaView));
    final fallback = first.errorBuilder!(
      context,
      Exception('thumbnail failed'),
      null,
    ) as Image;
    expect((fallback.image as NetworkImage).url, media.path);
    expect(fallback.fit, BoxFit.cover);
    final error = fallback.errorBuilder!(
      context,
      Exception('original failed'),
      null,
    );
    expect(error, isA<Center>());
    expect((error as Center).child, isA<AppIcon>());
  });

  testWidgets('network failures stop at the existing image error UI', (
    tester,
  ) async {
    const media = PostMedia(
      path: 'https://example.test/failing-original.jpg',
      thumbnailPath: 'https://example.test/failing-thumb.jpg',
      name: 'image',
      type: PostMediaType.image,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 120,
          height: 120,
          child: PostMediaView(media: media, preferThumbnail: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AppIcon && widget.asset == AppIcons.imageUnavailable,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final thumbnail in [null, '', 'not a url', 'https://']) {
    testWidgets('missing or invalid thumbnail $thumbnail uses original', (
      tester,
    ) async {
      final media = PostMedia(
        path: 'https://example.test/original.jpg',
        thumbnailPath: thumbnail,
        name: 'image',
        type: PostMediaType.image,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 120,
            height: 120,
            child: PostMediaView(media: media, preferThumbnail: true),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image).first);
      expect((image.image as NetworkImage).url, media.path);
      expect(
        image.errorBuilder!(
          tester.element(find.byType(PostMediaView)),
          Exception('failed'),
          null,
        ),
        isA<Center>(),
      );
    });
  }

  testWidgets('local images and video previews keep their existing paths', (
    tester,
  ) async {
    const local = PostMedia(
      path: '/tmp/local-original.jpg',
      thumbnailPath: 'https://example.test/thumb.jpg',
      name: 'local',
      type: PostMediaType.image,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 120,
          height: 120,
          child: PostMediaView(media: local, preferThumbnail: true),
        ),
      ),
    );
    expect(
      (tester.widget<Image>(find.byType(Image).first).image as FileImage)
          .file
          .path,
      local.path,
    );
    const video = PostMedia(
      path: '/tmp/video.mp4',
      thumbnailPath: '/tmp/video-preview.jpg',
      name: 'video',
      type: PostMediaType.video,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 120,
          height: 120,
          child: PostMediaView(media: video, preferThumbnail: true),
        ),
      ),
    );
    expect(
      (tester.widget<Image>(find.byType(Image).first).image as FileImage)
          .file
          .path,
      video.thumbnailPath,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is AppIcon && widget.asset == AppIcons.video,
      ),
      findsOneWidget,
    );
  });

  testWidgets('full-size media keeps the original URL', (tester) async {
    const media = PostMedia(
      path: 'https://example.test/original.jpg',
      thumbnailPath: 'https://example.test/thumb.jpg',
      name: 'image',
      type: PostMediaType.image,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: PostMediaView(media: media),
        ),
      ),
    );
    expect(
      (tester.widget<Image>(find.byType(Image).first).image as NetworkImage)
          .url,
      media.path,
    );
  });

  testWidgets(
    'Profile and Search use each post thumbnail while Home uses original',
    (tester) async {
      const first = PostItem(
        id: 'first',
        imageAsset: '',
        title: 'First',
        category: 'Mobile',
        stockCount: 0,
        price: '',
        originalPrice: '',
        media: [
          PostMedia(
            path: 'https://example.test/one.jpg',
            thumbnailPath: 'https://example.test/one-thumb.jpg',
            name: '',
            type: PostMediaType.image,
          ),
        ],
      );
      const second = PostItem(
        id: 'second',
        imageAsset: '',
        title: 'Second',
        category: 'Mobile',
        stockCount: 0,
        price: '',
        originalPrice: '',
        media: [
          PostMedia(
            path: 'https://example.test/two.jpg',
            thumbnailPath: 'https://example.test/two-thumb.jpg',
            name: '',
            type: PostMediaType.image,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Builder(
                    builder: (context) => ProfilePostCard(
                      post: first,
                      onTap: null,
                      contentScale: .65,
                      detailsHeight: ProfilePostCard.detailsHeightFor(
                        context,
                        .65,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 130,
                  child: SearchResultCard(post: second, contentScale: .65),
                ),
              ],
            ),
          ),
        ),
      );
      final media = tester
          .widgetList<PostMediaView>(find.byType(PostMediaView))
          .toList();
      expect(media.map((view) => view.preferThumbnail), [true, true]);
      expect(media.map((view) => view.media.thumbnailPath), [
        'https://example.test/one-thumb.jpg',
        'https://example.test/two-thumb.jpg',
      ]);
      final profileImage = tester.widget<Image>(
        find
            .descendant(
              of: find.byType(ProfilePostCard).first,
              matching: find.byType(Image),
            )
            .first,
      );
      final searchImage = tester.widget<Image>(
        find
            .descendant(
              of: find.byType(SearchResultCard),
              matching: find.byType(Image),
            )
            .first,
      );
      expect(
        (profileImage.image as NetworkImage).url,
        'https://example.test/one-thumb.jpg',
      );
      expect(
        (searchImage.image as NetworkImage).url,
        'https://example.test/two-thumb.jpg',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => PostDetailCubit(),
            child: Scaffold(
              body: HomePostMediaSlider(post: first, onTap: () {}),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<PostMediaView>(find.byType(PostMediaView))
            .preferThumbnail,
        false,
      );
      expect(
        (tester.widget<Image>(find.byType(Image).first).image as NetworkImage)
            .url,
        'https://example.test/one.jpg',
      );
    },
  );
  setUpAll(() async {
    await (FontLoader(
      'YekanBakh',
    )..addFont(rootBundle.load('assets/fonts/YekanBakh-Regular.ttf'))).load();
    await (FontLoader('ProfileCard')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Black.ttf')))
        .load();
  });

  test('Search results and suggestions include both published post types', () {
    final product = _post(title: 'Repair kit', published: true);
    final service = _post(
      title: 'Repair service',
      service: true,
      published: true,
    );
    final draft = _post(title: 'Unpublished repair draft');
    final posts = [product, service, draft];
    expect(SearchCatalog.resultsFor('تهران', '', publishedPosts: posts), [
      product,
      service,
    ]);
    final suggestions = SearchCatalog.suggestionsFor('', publishedPosts: posts);
    expect(suggestions, containsAll([product.title, service.title]));
    expect(suggestions, isNot(contains(draft.title)));
  });

  test(
    'Search keeps existing query filtering for both published post types',
    () {
      final product = _post(title: 'Repair kit', published: true);
      final service = _post(
        title: 'Repair service',
        service: true,
        published: true,
      );
      final posts = [product, service];
      expect(
        SearchCatalog.resultsFor('تهران', 'REPAIR', publishedPosts: posts),
        posts,
      );
      expect(
        SearchCatalog.resultsFor('تهران', 'repair kit', publishedPosts: posts),
        [product],
      );
      expect(
        SearchCatalog.resultsFor(
          'تهران',
          'repair service',
          publishedPosts: posts,
        ),
        [service],
      );
      expect(
        SearchCatalog.resultsFor('تهران', 'unrelated', publishedPosts: posts),
        isEmpty,
      );
      expect(
        SearchCatalog.suggestionsFor('repair', publishedPosts: posts),
        containsAll([product.title, service.title]),
      );
    },
  );

  for (final search in [false, true]) {
    for (final service in search ? [false, true] : [false]) {
      for (final width in [128.0, 200.0, 280.0]) {
        testWidgets(
          '${search ? 'Search' : 'Profile'} ${service ? 'service' : 'product'} card matches price placement at $width',
          (tester) async {
            var tapped = false;
            await tester.pumpWidget(
              _app(
                search: search,
                service: service,
                width: width,
                onTap: () => tapped = true,
              ),
            );
            await tester.pumpAndSettle();
            final old = tester.getRect(find.text('13,000'));
            final amount = tester.getRect(find.text('12,000'));
            final unit = tester.getRect(find.text('Meter'));
            final star = tester.getRect(
              find.byWidgetPredicate(
                (w) => w is AppIcon && w.asset == AppIcons.starFilled,
              ),
            );
            expect(old.left, closeTo(amount.left, .1));
            expect(old.bottom, lessThanOrEqualTo(amount.top + 1));
            expect(unit.left, greaterThan(amount.right));
            expect(star.left, greaterThan(unit.right));
            expect(
              tester.getRect(find.text('5')).left,
              greaterThanOrEqualTo(star.right),
            );
            final title = tester.widget<Text>(
              find.text('Wireless\nBluetooth Headphones'),
            );
            expect(title.maxLines, 2);
            expect(title.textAlign, TextAlign.right);
            expect(title.textDirection, TextDirection.rtl);
            final category = tester.widget<Text>(
              find.text(service ? 'Services' : 'Mobile'),
            );
            final surface = Theme.of(
              tester.element(find.byType(ProfilePostCard)),
            ).colorScheme.onSurface;
            expect(category.style!.color, surface.withValues(alpha: .4));
            expect(
              tester
                  .widget<Visibility>(
                    find.ancestor(
                      of: find.text('2 in stock', skipOffstage: false),
                      matching: find.byType(Visibility),
                    ),
                  )
                  .visible,
              !service,
            );
            await tester.tap(find.text('Wireless\nBluetooth Headphones'));
            expect(tapped, isTrue);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (width == 200 &&
                const bool.fromEnvironment('CAPTURE_GRID_CARD')) {
              await tester.runAsync(
                () => precacheImage(
                  const AssetImage('assets/img1.png'),
                  tester.element(find.byType(ProfilePostCard)),
                ),
              );
              await tester.pumpAndSettle();
              await expectLater(
                find.byKey(const ValueKey('grid-card-preview')),
                matchesGoldenFile(
                  '/tmp/hywork-${search ? 'search' : 'profile'}-card.png',
                ),
              );
            }
          },
        );
      }
    }
  }

  for (final search in [false, true]) {
    testWidgets(
      '${search ? 'Search' : 'Profile'} short title does not reserve an empty second line',
      (tester) async {
        const shortTitle = 'IPhone 18 pro max';
        await tester.pumpWidget(_app(search: search, title: shortTitle));
        await tester.pumpAndSettle();
        final heading = tester.getRect(find.text(shortTitle));
        final category = tester.getRect(find.text('Mobile'));
        final shortPriceTop = tester.getTopLeft(find.text('13,000')).dy;
        expect(category.top, closeTo(heading.bottom, .1));
        await tester.pumpWidget(_app(search: search));
        await tester.pumpAndSettle();
        final longHeading = tester.getRect(
          find.text('Wireless\nBluetooth Headphones'),
        );
        final longPriceTop = tester.getTopLeft(find.text('13,000')).dy;
        expect(shortPriceTop, lessThan(longPriceTop));
        expect(
          longPriceTop - shortPriceTop,
          closeTo(longHeading.height - heading.height, .1),
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${search ? 'Search' : 'Profile'} full price does not reserve an empty discount line',
      (tester) async {
        await tester.pumpWidget(_app(search: search));
        await tester.pumpAndSettle();
        final discountedTop = tester.getTopLeft(find.text('12,000')).dy;
        final discountHeight = tester.getSize(find.text('13,000')).height;
        await tester.pumpWidget(_app(search: search, discounted: false));
        await tester.pumpAndSettle();
        expect(find.text('13,000'), findsNothing);
        final fullPriceTop = tester.getTopLeft(find.text('12,000')).dy;
        expect(discountedTop - fullPriceTop, closeTo(discountHeight, .1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Search service pricing does not reserve an empty stock row', (
    tester,
  ) async {
    await tester.pumpWidget(_app(search: true));
    await tester.pumpAndSettle();
    final productPriceTop = tester.getTopLeft(find.text('13,000')).dy;
    await tester.pumpWidget(_app(search: true, service: true));
    await tester.pumpAndSettle();
    expect(find.text('2 in stock'), findsNothing);
    expect(
      tester.getTopLeft(find.text('13,000')).dy,
      lessThan(productPriceTop),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long titles stop at two lines, without a fabricated rating', (
    tester,
  ) async {
    const title =
        'A very long heading that should occupy two lines and then truncate rather than changing the grid layout';
    await tester.pumpWidget(_app(title: title, rating: false));
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(find.text('5'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calculated card height accommodates large text', (tester) async {
    await tester.pumpWidget(_app(width: 200, textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
