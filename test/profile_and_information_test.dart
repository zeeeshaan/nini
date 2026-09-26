import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_app/data/post_store.dart';
import 'package:simple_app/data/product_info.dart';
import 'package:simple_app/data/shop_categories.dart';
import 'package:simple_app/screens/information_screen.dart';
import 'package:simple_app/screens/post_details_screen.dart';
import 'package:simple_app/screens/user_screen.dart';
import 'package:simple_app/theme.dart';

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('fa', 'IR'),
  supportedLocales: const [Locale('fa', 'IR')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

PostDraft _post({
  String title = 'تویوتا کرولا',
  String? category,
  List<ProductAttribute> information = const [],
  List<ProductVariant> variants = const [ProductVariant()],
}) => PostDraft(
  media: const [],
  type: null,
  category: category,
  title: title,
  caption: '',
  altTexts: const {},
  scheduledAt: null,
  tags: const [],
  location: '',
  information: information,
  variants: variants,
);

void main() {
  setUpAll(() async {
    final font = File('assets/fonts/YekanBakh-Regular.ttf').readAsBytes();
    await (FontLoader(
      'YekanBakh',
    )..addFont(font.then((b) => ByteData.sublistView(b)))).load();
  });

  tearDown(() {
    PostStore.posts.value = const [];
    ShopCategories.all.value = ShopCategories.defaults;
  });

  testWidgets('published products are listed and can be reused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    const attrs = [
      ProductAttribute('رنگ', ['آبی', 'قرمز']),
    ];
    PostStore.add(
      _post(
        information: attrs,
        variants: const [
          ProductVariant(values: {'رنگ': 'آبی'}, price: 99000, unit: 'ساعت'),
          ProductVariant(values: {'رنگ': 'قرمز'}, price: 85000),
        ],
      ),
    );

    List<ProductAttribute>? result;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await openInformation(context, const []),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // One card per variant.
    expect(find.text('تویوتا کرولا'), findsNWidgets(2));
    expect(find.text('۹۹٬۰۰۰ تومان / ساعت'), findsOneWidget);
    expect(find.text('۸۵٬۰۰۰ تومان / عدد'), findsOneWidget);

    await tester.tap(find.text('آبی'));
    await tester.pumpAndSettle();
    expect(find.text('ویژگی‌ها'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result!.single.name, 'رنگ');
    expect(result!.single.values, ['آبی', 'قرمز']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a category added on the profile filters the grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    PostStore.add(_post(title: 'گوشی شیائومی', category: 'موبایل'));
    PostStore.add(_post(title: 'پنل خورشیدی', category: 'انرژی'));
    await tester.pumpWidget(_app(const Scaffold(body: UserScreen())));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('افزودن دسته‌بندی'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'موبایل');
    await tester.tap(find.text('تأیید'));
    await tester.pumpAndSettle();

    expect(ShopCategories.all.value.first, 'موبایل');
    // The new chip is picked: only the post filed under it remains.
    expect(find.text('گوشی شیائومی'), findsOneWidget);
    expect(find.text('پنل خورشیدی'), findsNothing);

    await tester.tap(find.text('همه'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('پنل خورشیدی'), findsOneWidget);

    await tester.tap(find.text('طراحی وب'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('هنوز پستی در این دسته‌بندی نیست.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
