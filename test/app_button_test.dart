import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_details_screen.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

Material buttonMaterial(WidgetTester tester, Finder button) => tester.widget(
  find.descendant(of: button, matching: find.byType(Material)).first,
);

Color? labelColor(WidgetTester tester, String label) => tester
    .widget<RichText>(
      find.descendant(of: find.text(label), matching: find.byType(RichText)),
    )
    .text
    .style
    ?.color;

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final background = mode == ThemeMode.dark ? Colors.white : Colors.black;
    final foreground = mode == ThemeMode.dark ? Colors.black : Colors.white;

    testWidgets('Primary and outlined buttons contrast in $mode', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  label: AppStrings.publish,
                  icon: const AppIcon(AppIcons.add),
                  onPressed: () => taps++,
                ),
                AppButton(
                  label: AppStrings.cancel,
                  variant: AppButtonVariant.outlined,
                  icon: const Icon(Icons.close),
                  onPressed: () {},
                ),
                FilledButton(
                  onPressed: () {},
                  child: const Text(AppStrings.done),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final type in [ElevatedButton, FilledButton]) {
        expect(buttonMaterial(tester, find.byType(type)).color, background);
      }
      expect(labelColor(tester, AppStrings.publish), foreground);
      expect(labelColor(tester, AppStrings.done), foreground);
      expect(tester.widget<Image>(find.byType(Image)).color, foreground);
      final outlined = buttonMaterial(tester, find.byType(OutlinedButton));
      expect(outlined.color, foreground);
      expect((outlined.shape as OutlinedBorder).side.style, BorderStyle.solid);
      expect(labelColor(tester, AppStrings.cancel), background);
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.close))).color,
        background,
      );

      await tester.tap(find.text(AppStrings.publish));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Loading buttons keep contrasting spinners in $mode', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Scaffold(
            body: Column(
              children: [
                for (final variant in AppButtonVariant.values)
                  AppButton(
                    label: variant.name,
                    variant: variant,
                    isLoading: true,
                    onPressed: () => taps++,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      for (final variant in AppButtonVariant.values) {
        final button = find.byWidgetPredicate(
          (widget) => widget is AppButton && widget.variant == variant,
        );
        final spinner = tester.widget<CircularProgressIndicator>(
          find.descendant(
            of: button,
            matching: find.byType(CircularProgressIndicator),
          ),
        );
        final expected = variant == AppButtonVariant.primary
            ? foreground
            : background;
        expect(spinner.color, expected);
        expect(labelColor(tester, variant.name), expected);
      }
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(
        buttonMaterial(tester, find.byType(ElevatedButton)).color,
        background,
      );
      await tester.tap(find.text('primary'));
      expect(taps, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Create-post actions update with the theme and keep the draft', (
    tester,
  ) async {
    final mode = ValueNotifier(ThemeMode.light);
    final draft = CreatePostCubit()..updateTitle('Existing draft');
    addTearDown(mode.dispose);
    addTearDown(draft.close);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (context, mode, child) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: child,
        ),
        child: BlocProvider.value(
          value: draft,
          child: const CreatePostDetailsScreen(attachments: []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      buttonMaterial(tester, find.byType(ElevatedButton)).color,
      Colors.black,
    );
    expect(labelColor(tester, AppStrings.publish), Colors.white);
    expect(labelColor(tester, AppStrings.cancel), Colors.black);

    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(
      buttonMaterial(tester, find.byType(ElevatedButton)).color,
      Colors.white,
    );
    expect(labelColor(tester, AppStrings.publish), Colors.black);
    expect(
      buttonMaterial(tester, find.byType(OutlinedButton)).color,
      Colors.black,
    );
    expect(labelColor(tester, AppStrings.cancel), Colors.white);
    expect(draft.state.title, 'Existing draft');
    expect(find.text('Existing draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
