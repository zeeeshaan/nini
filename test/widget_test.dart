import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_app/main.dart';

void main() {
  testWidgets('App is Persian RTL and moves from splash to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SimpleApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('های‌ورک'), findsOneWidget);
    expect(find.text('ورود با حساب گوگل'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('های‌ورک'))),
      TextDirection.rtl,
    );

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ورود با حساب گوگل'), findsOneWidget);
  });
}
