import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/home/presentation/widgets/common/home_badge.dart';
import 'package:nini/features/home/presentation/widgets/common/home_post_pricing.dart';
import 'package:nini/features/home/presentation/widgets/published/home_published_post_card.dart';
import 'package:nini/features/home/presentation/widgets/sample_product/home_product_details.dart';
import 'package:nini/shared/models/post/post_item.dart';

PostItem _post({
  String title = 'Product title',
  bool service = false,
  String price = '12000',
  String original = '13000',
}) => PostItem(
  id: 'pricing-post',
  imageAsset: 'assets/img1.png',
  title: title,
  category: service ? 'Services' : 'Product',
  stockCount: 2,
  price: price,
  originalPrice: original,
  details: PostDetails(unit: service ? PostUnit.hour : PostUnit.piece),
);

Widget _app(Widget child, {double width = 390, double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    final body = FontLoader('YekanBakh')
      ..addFont(rootBundle.load('assets/fonts/YekanBakh-Regular.ttf'));
    final price = FontLoader('ProfileCard')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Black.ttf'));
    await body.load();
    await price.load();
  });

  testWidgets('old price sits above amount on left and badge stays on right', (
    tester,
  ) async {
    await tester.pumpWidget(_app(HomePostPricing(post: _post())));
    await tester.pumpAndSettle();
    final old = tester.getRect(find.text('13,000'));
    final current = tester.getRect(find.text('12,000'));
    final badge = tester.getRect(find.byType(HomeBadge));
    final bounds = tester.getRect(find.byType(HomePostPricing));
    expect(old.left, closeTo(current.left, 1));
    expect(old.bottom, lessThanOrEqualTo(current.top + 1));
    expect(current.top - old.bottom, closeTo(0, .1));
    expect(badge.right, closeTo(bounds.right, .1));
    expect(badge.bottom, closeTo(bounds.bottom - 6, .1));
    expect(current.left, lessThan(bounds.left + 14));
    expect(tester.getRect(find.text('item')).left, greaterThan(current.right));
    expect(
      tester.widget<Text>(find.text('13,000')).style!.decoration,
      TextDecoration.lineThrough,
    );
    expect(tester.widget<Text>(find.text('تومان')).style!.fontSize, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('service prices retain their unit and have no stock badge', (
    tester,
  ) async {
    await tester.pumpWidget(_app(HomePostPricing(post: _post(service: true))));
    await tester.pumpAndSettle();
    expect(find.text('hour'), findsOneWidget);
    expect(find.byType(HomeBadge), findsNothing);
  });

  testWidgets('unchanged price is not repeated as a discount', (tester) async {
    await tester.pumpWidget(
      _app(HomePostPricing(post: _post(original: '12000'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('12,000'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'narrow pricing stays readable without overflow at scale $scale',
      (tester) async {
        await tester.pumpWidget(
          _app(
            HomePostPricing(
              post: _post(price: '160000', original: '200000'),
            ),
            width: 240,
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('160,000'), findsOneWidget);
        expect(find.text('2 in stock'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'published long titles stop at two right-aligned lines with ellipsis',
    (tester) async {
      const title =
          'An extremely long product heading that cannot fit on a single line in the Home feed';
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: HomePublishedPostCard(post: _post(title: title)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final widget = tester.widget<Text>(find.text(title));
      expect(widget.maxLines, 2);
      expect(widget.softWrap, isTrue);
      expect(widget.overflow, TextOverflow.ellipsis);
      expect(widget.textAlign, TextAlign.right);
      expect(widget.textDirection, TextDirection.rtl);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(title))
            .didExceedMaxLines,
        isTrue,
      );
      final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
      final lines = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: title.length),
          )
          .map((box) => box.top)
          .toSet();
      expect(lines.length, 2);
      expect(tester.widget<Text>(find.text('Product')).style!.fontSize, 22);
    },
  );

  if (const bool.fromEnvironment('CAPTURE_HOME_PRICING')) {
    testWidgets('capture Home price section for visual review', (tester) async {
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: const ValueKey('pricing-preview'),
            child: ColoredBox(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HomeProductDetails(
                    title: 'An exceptionally long product heading to show the title truncation',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: HomePostPricing(post: _post()),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('pricing-preview')),
        matchesGoldenFile('/tmp/hywork-home-pricing.png'),
      );
    });
  }
}
