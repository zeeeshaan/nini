import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';
import 'package:nini/features/search/presentation/widgets/results/search_result_card.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

PostItem _post({
  String title = 'Wireless\nBluetooth Headphones',
  bool rating = true,
}) => PostItem.fromJson({
  'id': 'layout-post',
  'imageAsset': 'assets/img1.png',
  'title': title,
  'category': 'Mobile',
  'stockCount': 2,
  'price': '12000',
  'originalPrice': '13000',
  'metadata': {'unit': 'meter', 'warehouseStock': '2', if (rating) 'rating': 5},
});

Widget _app({
  bool search = false,
  double width = 200,
  double textScale = 1,
  String title = 'Wireless\nBluetooth Headphones',
  bool rating = true,
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
              final post = _post(title: title, rating: rating);
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

  for (final search in [false, true]) {
    for (final width in [128.0, 200.0, 280.0]) {
      testWidgets(
        '${search ? 'Search' : 'Profile'} card matches price placement at $width',
        (tester) async {
          var tapped = false;
          await tester.pumpWidget(
            _app(search: search, width: width, onTap: () => tapped = true),
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
            find.text(search ? 'Services' : 'Mobile'),
          );
          final surface = Theme.of(tester.element(find.byType(ProfilePostCard)))
              .colorScheme
              .onSurface;
          expect(category.style!.color, surface.withValues(alpha: .4));
          expect(
            tester
                .widget<Visibility>(
                  find.ancestor(
                    of: find.text('2 in stock'),
                    matching: find.byType(Visibility),
                  ),
                )
                .visible,
            !search,
          );
          await tester.tap(find.text('Wireless\nBluetooth Headphones'));
          expect(tapped, isTrue);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (width == 200 && const bool.fromEnvironment('CAPTURE_GRID_CARD')) {
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
