import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_app/data/product_info.dart';
import 'package:simple_app/theme.dart';
import 'package:simple_app/widgets/variants_editor.dart';

/// Hosts a [VariantsEditor] in a scaffold, keeping its variants in state.
class _Host extends StatefulWidget {
  const _Host({required this.attributes, this.picker});

  final List<ProductAttribute> attributes;
  final ValueNotifier<Set<String>?>? picker;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<ProductVariant> variants = syncVariants(const [
    ProductVariant(),
  ], widget.attributes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          VariantsEditor(
            attributes: widget.attributes,
            variants: variants,
            onChanged: (v) => setState(() => variants = v),
            downloadPicker: widget.picker,
          ),
        ],
      ),
    );
  }
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('fa', 'IR'),
  supportedLocales: const [Locale('fa', 'IR')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1080,
      2340,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3;
  });

  _HostState host(WidgetTester tester) =>
      tester.state<_HostState>(find.byType(_Host));

  testWidgets('an attribute value is picked from the dark sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const _Host(
          attributes: [
            ProductAttribute('رنگ', ['مشکی', 'سفید']),
          ],
        ),
      ),
    );

    await tester.tap(find.text('هر رنگ'));
    await tester.pumpAndSettle();
    expect(find.text('انتخاب مقدار ویژگی'), findsOneWidget);

    await tester.tap(find.text('سفید'));
    await tester.pump();
    await tester.tap(find.text('تأیید'));
    await tester.pumpAndSettle();
    expect(host(tester).variants.single.values['رنگ'], 'سفید');

    // Cancelling keeps the value; picking "any" clears it.
    await tester.tap(find.text('سفید'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    expect(host(tester).variants.single.values['رنگ'], 'سفید');

    await tester.tap(find.text('سفید'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('هر رنگ'));
    await tester.pump();
    await tester.tap(find.text('تأیید'));
    await tester.pumpAndSettle();
    expect(host(tester).variants.single.values['رنگ'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the discount box shows the percentage off', (tester) async {
    await tester.pumpWidget(_app(const _Host(attributes: [])));
    expect(find.text('٪'), findsOneWidget);

    final amounts = find.byType(TextField);
    await tester.enterText(amounts.at(0), '200000');
    await tester.enterText(amounts.at(1), '150000');
    await tester.pump();
    expect(find.text('٪۲۵'), findsOneWidget);
  });

  testWidgets('downloadable files are picked through the shared picker', (
    tester,
  ) async {
    final picker = ValueNotifier<Set<String>?>(null);
    addTearDown(picker.dispose);
    await tester.pumpWidget(_app(_Host(attributes: const [], picker: picker)));

    final row = find.textContaining('فایل‌های قابل دانلود ·');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(picker.value, isEmpty);

    // The grid would do this: pick two files.
    picker.value = {'f:a', 'f:b'};
    await tester.pump();
    expect(find.text('۲ فایل انتخاب شده'), findsOneWidget);

    await tester.tap(find.text('تأیید'));
    await tester.pumpAndSettle();
    expect(picker.value, isNull);
    expect(
      host(tester).variants.single.downloadFiles,
      unorderedEquals(['f:a', 'f:b']),
    );
    expect(find.textContaining('۲ فایل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
