import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_app/main.dart';

void main() {
  testWidgets('App shows Home tab with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const SimpleApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
