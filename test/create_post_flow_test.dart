import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_app/data/post_store.dart';
import 'package:simple_app/screens/create_post_screen.dart';
import 'package:simple_app/screens/post_details_screen.dart';
import 'package:simple_app/screens/user_screen.dart';
import 'package:simple_app/theme.dart';
import 'package:simple_app/widgets/pill_picker.dart';

/// A picked file that never touches disk; only its name and uri are read.
final class _FakeFile extends PlatformFile {
  _FakeFile(this.name);

  @override
  final String name;

  @override
  Uri get uri => Uri.parse('memory:///$name');

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => 0;

  @override
  Future<int?> length() async => 0;

  @override
  Never readAsBytes() => throw UnimplementedError();

  @override
  Never readAsByteStream() => throw UnimplementedError();
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('fa', 'IR'),
  supportedLocales: const [Locale('fa', 'IR')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

void main() {
  setUpAll(() async {
    final font = File('assets/fonts/YekanBakh-Regular.ttf').readAsBytes();
    await (FontLoader(
      'YekanBakh',
    )..addFont(font.then((b) => ByteData.sublistView(b)))).load();
  });

  tearDown(() => PostStore.posts.value = const []);

  testWidgets('a published post carries its price and stock to the profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    PostDraft? published;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              published = await Navigator.of(context).push<PostDraft>(
                MaterialPageRoute(
                  builder: (_) => const PostDetailsScreen(media: []),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Future<void> tapVisible(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.byType(TextField).first, 'گوشی تست');

    // Fields in order: title, caption, location, price, discount, SKU.
    final amounts = find.byType(TextField);
    await tester.ensureVisible(amounts.at(3));
    await tester.enterText(amounts.at(3), '625000');
    await tester.enterText(amounts.at(4), '620000');
    await tester.pump();
    expect(find.text('۶۲۵٬۰۰۰'), findsOneWidget);
    expect(find.text('۶۲۰٬۰۰۰'), findsOneWidget);

    // Warehouse stock: 1 -> 3.
    final stockPlus = find.byIcon(Icons.add).at(0);
    await tapVisible(stockPlus);
    await tapVisible(stockPlus);

    await tapVisible(find.text('واحد'));
    await tapVisible(find.text('بسته'));
    await tapVisible(find.text('تأیید'));
    expect(find.text('واحد: بسته'), findsOneWidget);

    await tapVisible(find.text('انتشار'));
    expect(tester.takeException(), isNull);

    final v = published!.variants.single;
    expect(published!.title, 'گوشی تست');
    expect(v.price, 625000);
    expect(v.discountPrice, 620000);
    expect(v.stock, 3);
    expect(v.unit, 'بسته');

    PostStore.add(published!);
    await tester.pumpWidget(_app(const Scaffold(body: UserScreen())));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('گوشی تست'), findsOneWidget);
    expect(find.text('۶۲۰٬۰۰۰ تومان', findRichText: true), findsOneWidget);
    expect(find.text('۶۲۵٬۰۰۰'), findsOneWidget);
    expect(find.text('۳ بسته در انبار'), findsOneWidget);
    expect(find.text('۳۸۶'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discount must be below the price', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const PostDetailsScreen(media: [])));
    await tester.enterText(find.byType(TextField).first, 'x');
    final amounts = find.byType(TextField);
    await tester.enterText(amounts.at(3), '100');
    await tester.enterText(amounts.at(4), '200');
    await tester.pump();

    expect(
      find.text('قیمت با تخفیف باید کمتر از قیمت اصلی باشد'),
      findsOneWidget,
    );
  });

  testWidgets('the Feature page reviews the picked rows before confirming', (
    tester,
  ) async {
    List<String>? picked;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await Navigator.of(context).push<List<String>>(
                MaterialPageRoute(
                  builder: (_) => const PillPickerScreen(
                    title: 'ویژگی',
                    options: ['رنگ', 'رم', 'سال تولید'],
                    multi: true,
                    numbered: true,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('سال تولید'));
    await tester.pump();
    await tester.tap(find.text('رم'));
    await tester.pump();

    // First check: only the picked features remain, in pick order.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('رنگ'), findsNothing);
    expect(find.text('سال تولید'), findsOneWidget);
    expect(find.text('۱'), findsOneWidget);
    expect(find.text('۲'), findsOneWidget);
    expect(picked, isNull);

    // Back returns to the full list instead of leaving the page.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('رنگ'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(picked, ['سال تولید', 'رم']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('downloadable files are picked on the post media grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final pdf = PickedMedia.file(_FakeFile('manual.pdf'));
    final mkv = PickedMedia.file(_FakeFile('clip.mkv'));
    PostDraft? published;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              published = await Navigator.of(context).push<PostDraft>(
                MaterialPageRoute(
                  builder: (_) => PostDetailsScreen(media: [pdf, mkv]),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'فایل');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    final row = find.textContaining('فایل‌های قابل دانلود ·');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    // The page scrolled back to the grid; tap the PDF tile.
    await tester.tap(find.text('PDF'));
    await tester.pump();
    expect(find.text('۱ فایل انتخاب شده'), findsOneWidget);
    await tester.tap(find.text('تأیید'));
    await tester.pumpAndSettle();

    // Selection circles are gone once the sheet closes.
    await tester.tap(find.text('PDF'));
    await tester.pump();
    expect(find.text('۱ فایل انتخاب شده'), findsNothing);

    await tester.tap(find.text('انتشار'));
    await tester.pumpAndSettle();
    expect(published!.variants.single.downloadFiles, [pdf.id]);
    expect(tester.takeException(), isNull);
  });
}
