import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_app/screens/analytics_screen.dart';
import 'package:simple_app/screens/post_screen.dart';
import 'package:simple_app/theme.dart';

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('fa', 'IR'),
  supportedLocales: const [Locale('fa', 'IR')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) =>
      Directionality(textDirection: TextDirection.rtl, child: child!),
  home: home,
);

void main() {
  setUpAll(() async {
    final font = File('assets/fonts/YekanBakh-Regular.ttf').readAsBytes();
    await (FontLoader(
      'YekanBakh',
    )..addFont(font.then((b) => ByteData.sublistView(b)))).load();
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('the service post opens its analytics', (tester) async {
    phone(tester);
    await tester.pumpWidget(_app(const PostScreen()));
    await tester.tap(find.byTooltip('گزینه‌ها'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('آمار و تحلیل'));
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsScreen), findsOneWidget);
    expect(find.text('کل بازدیدها'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every chart renders, switches period and shows a table', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(_app(AnalyticsScreen(now: DateTime(2026, 9, 27))));
    await tester.pumpAndSettle();

    // Scroll through every card; none may overflow.
    for (final title in [
      'کلیک‌ها / تعامل‌ها',
      'میانگین زمان مشاهده',
      'نمایش‌ها',
      'کل سفارش‌ها / رزروها',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('کل بازدیدها'), -200);
    await tester.pumpAndSettle();
    final before = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    await tester.tap(find.text('۶ ماه').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('۱۲ ماه اخیر'));
    await tester.pumpAndSettle();
    expect(find.text('۱۲ ماه'), findsOneWidget);
    // Only the first card changed period.
    expect(find.text('۶ ماه'), findsWidgets);
    final after = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(after, isNot(before));

    // The first card's table lists all 12 months.
    await tester.tap(find.byTooltip('نمایش جدول').first);
    await tester.pumpAndSettle();
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('مهر'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
