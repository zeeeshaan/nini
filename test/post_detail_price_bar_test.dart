import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/localization/strings/post_detail_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_pricing.dart';
import 'package:nini/features/post_detail/presentation/widgets/purchase_actions/post_purchase_actions.dart';
import 'package:nini/features/post_detail/presentation/widgets/purchase_actions/post_service_purchase_actions.dart';
import 'package:nini/shared/models/post/post_item.dart';

PostItem _post({
  bool service = false,
  String price = '160000',
  String original = '200000',
  bool unit = true,
}) => PostItem(
  id: 'price-bar-post',
  imageAsset: 'assets/img1.png',
  title: 'Post',
  category: service ? 'Services' : 'Product',
  stockCount: 2,
  price: price,
  originalPrice: original,
  details: PostDetails(unit: unit ? PostUnit.meter : null),
);

Widget _host(Widget child, {double width = 390, double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.dark,
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

Widget _actions(PostItem post, ValueChanged<int> onQuantity) => post.isService
    ? PostServicePurchaseActions(
        post: post,
        quantity: 100,
        maximum: 1000,
        onQuantityChanged: onQuantity,
      )
    : PostPurchaseActions(
        post: post,
        quantity: 100,
        maximum: 1000,
        onQuantityChanged: onQuantity,
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

  for (final service in [false, true]) {
    testWidgets(
      '${service ? 'service' : 'product'} discount is small above current price and unit',
      (tester) async {
        var quantity = 0;
        await tester.pumpWidget(
          _host(_actions(_post(service: service), (value) => quantity = value)),
        );
        await tester.pumpAndSettle();
        final old = find.text('200,000');
        final current = find.text('160,000');
        final unit = find.text('Meter');
        final currency = find.text('تومان');
        expect(currency, findsOneWidget);
        final rotation = find.ancestor(
          of: currency,
          matching: find.byType(RotatedBox),
        );
        expect(tester.widget<RotatedBox>(rotation).quarterTurns, 3);
        expect(tester.widget<Text>(currency).textDirection, TextDirection.rtl);
        expect(
          tester.getRect(rotation).right,
          lessThan(tester.getRect(current).left),
        );
        expect(
          tester.getSize(rotation).height,
          greaterThan(tester.getSize(rotation).width),
        );
        expect(
          tester.getRect(old).left,
          closeTo(tester.getRect(current).left, .1),
        );
        expect(old, findsOneWidget);
        expect(unit, findsOneWidget);
        expect(
          tester.getRect(old).bottom,
          lessThanOrEqualTo(tester.getRect(current).top + 1),
        );
        expect(
          tester.getRect(unit).left,
          greaterThan(tester.getRect(current).right),
        );
        expect(
          tester.widget<Text>(old).style!.fontSize,
          lessThan(tester.widget<Text>(current).style!.fontSize!),
        );
        expect(
          tester.widget<Text>(old).style!.decoration,
          TextDecoration.lineThrough,
        );
        expect(tester.widget<Text>(current).style!.fontSize, 26);
        final amountRender = tester.renderObject<RenderParagraph>(current);
        final unitRender = tester.renderObject<RenderParagraph>(unit);
        final amountBaseline = amountRender
            .localToGlobal(
              Offset(
                0,
                amountRender.getDryBaseline(
                  BoxConstraints.tight(amountRender.size),
                  TextBaseline.alphabetic,
                )!,
              ),
            )
            .dy;
        final unitBaseline = unitRender
            .localToGlobal(
              Offset(
                0,
                unitRender.getDryBaseline(
                  BoxConstraints.tight(unitRender.size),
                  TextBaseline.alphabetic,
                )!,
              ),
            )
            .dy;
        expect(amountBaseline, closeTo(unitBaseline, .1));
        await tester.tap(find.byTooltip(PostDetailStrings.increaseQuantity));
        expect(quantity, 200);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${service ? 'service' : 'product'} without discount shows large current price and unit only',
      (tester) async {
        await tester.pumpWidget(
          _host(
            _actions(
              _post(service: service, price: '856000', original: ''),
              (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('856,000'), findsOneWidget);
        expect(find.text('Meter'), findsOneWidget);
        expect(tester.widget<Text>(find.text('856,000')).style!.fontSize, 26);
        expect(
          tester
              .widgetList<Text>(find.byType(Text))
              .where(
                (text) => text.style?.decoration == TextDecoration.lineThrough,
              ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${service ? 'service' : 'product'} price bar still fits narrow screens with large text',
      (tester) async {
        await tester.pumpWidget(
          _host(
            _actions(_post(service: service), (_) {}),
            width: 200,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('160,000'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('equivalent formatted amounts are not treated as a discount', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PostPricing(
          post: _post(price: '856000', original: '856,000'),
        ),
      ),
    );
    expect(find.text('856,000'), findsOneWidget);
    expect(find.text('Meter'), findsOneWidget);
  });

  testWidgets('service posts retain the existing fallback unit', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_actions(_post(service: true, unit: false), (_) {})),
    );
    expect(find.text('Session'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  if (const bool.fromEnvironment('CAPTURE_PRICE_BAR')) {
    for (final discount in [false, true]) {
      testWidgets('capture ${discount ? 'discounted' : 'regular'} price bar', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            RepaintBoundary(
              key: const ValueKey('price-bar-preview'),
              child: ColoredBox(
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    heightFactor: 1,
                    child: PostPricing(
                      post: _post(
                        price: discount ? '160000' : '856000',
                        original: discount ? '200000' : '',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('price-bar-preview')),
          matchesGoldenFile(
            '/tmp/hywork-price-bar-${discount ? 'discount' : 'regular'}.png',
          ),
        );
      });
    }
  }
}
