import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/core/theme/theme_cubit.dart';
import 'package:nini/core/theme/theme_mode_menu.dart';
import 'package:nini/features/home/presentation/widgets/home_post_card/home_post_card.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/main.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'support/empty_posts_repository.dart';

Finder clientIcon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

/// Check rendered text and vector/legacy raster tints, including disabled buttons.
void expectForeground(WidgetTester tester, Color color) {
  for (final element in find.byType(AppIcon).evaluate()) {
    final icon = element.widget as AppIcon;
    final descendants = find.descendant(
      of: find.byElementPredicate((candidate) => identical(candidate, element)),
      matching: find.byType(icon.asset.endsWith('.svg') ? SvgPicture : Image),
    );
    if (icon.asset.endsWith('.svg')) {
      expect(
        tester.widget<SvgPicture>(descendants).colorFilter,
        ColorFilter.mode(color, BlendMode.srcIn),
        reason: icon.asset,
      );
      expect(
        tester.widget<SvgPicture>(descendants).renderingStrategy.name,
        'picture',
        reason: icon.asset,
      );
    } else {
      expect(
        tester.widget<Image>(descendants).color,
        color,
        reason: icon.asset,
      );
    }
  }
  for (final element in find.byType(Text).evaluate()) {
    final richText = find.descendant(
      of: find.byElementPredicate((candidate) => identical(candidate, element)),
      matching: find.byType(RichText),
    );
    if (richText.evaluate().isNotEmpty) {
      expect(
        tester.widget<RichText>(richText).text.style?.color,
        color,
        reason: (element.widget as Text).data,
      );
    }
  }
}

void main() {
  test(
    'Theme controller supports explicit modes, system, and effective toggle',
    () {
      final cubit = ThemeCubit();
      addTearDown(cubit.close);
      expect(cubit.state, ThemeMode.system);
      cubit.toggleTheme(Brightness.dark);
      expect(cubit.state, ThemeMode.light);
      cubit.useSystemTheme();
      cubit.toggleTheme(Brightness.light);
      expect(cubit.state, ThemeMode.dark);
      cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state, ThemeMode.light);
      cubit.useSystemTheme();
      expect(cubit.state, ThemeMode.system);
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    test('Buttons use the exact foreground in ${theme.brightness} mode', () {
      final foreground = theme.brightness == Brightness.dark
          ? Colors.white
          : Colors.black;
      for (final states in [
        <WidgetState>{},
        {WidgetState.disabled},
      ]) {
        for (final style in [
          theme.elevatedButtonTheme.style!,
          theme.filledButtonTheme.style!,
        ]) {
          expect(style.backgroundColor!.resolve(states), foreground);
          expect(
            style.foregroundColor!.resolve(states),
            theme.colorScheme.onPrimary,
          );
          expect(style.iconColor!.resolve(states), theme.colorScheme.onPrimary);
        }
        for (final style in [
          theme.outlinedButtonTheme.style!,
          theme.textButtonTheme.style!,
          theme.iconButtonTheme.style!,
        ]) {
          expect(style.foregroundColor!.resolve(states), foreground);
          expect(style.iconColor!.resolve(states), foreground);
        }
      }
    });
  }

  testWidgets(
    'Theme menu updates home and a pushed post without losing state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ResponsiveConfig(
          child: MyApp(
            initialThemeMode: ThemeMode.light,
            postsRepository: EmptyPostsRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expectForeground(tester, Colors.black);

      await tester.tap(find.byTooltip(AppStrings.appearance));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CheckedPopupMenuItem<ThemeMode> &&
              widget.value == ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      final homeContext = tester.element(find.byType(ThemeModeMenu));
      expect(Theme.of(homeContext).brightness, Brightness.dark);
      expect(Theme.of(homeContext).scaffoldBackgroundColor, Colors.black);
      expectForeground(tester, Colors.white);

      await tester.tap(find.byType(HomePostCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(PostDetailScreen), findsOneWidget);
      expect(find.text('${AppStrings.price}:'), findsOneWidget);
      expect(find.text('۱۲٬۰۰۰'), findsOneWidget);
      expect(
        find.text('${AppStrings.unit}: ${AppStrings.unitPiece}'),
        findsOneWidget,
      );
      expectForeground(tester, Colors.white);

      await tester.tap(clientIcon(AppIcons.heart));
      await tester.tap(clientIcon(AppIcons.bookmark));
      await tester.pumpAndSettle();
      final postContext = tester.element(clientIcon(AppIcons.heart));
      final postCubit = postContext.read<PostDetailCubit>();
      expect(postCubit.state.isLiked, isTrue);
      expect(postCubit.state.isBookmarked, isTrue);
      expectForeground(tester, Colors.white);

      postContext.read<ThemeCubit>().setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(find.byType(PostDetailScreen), findsOneWidget);
      expect(postCubit.state.isLiked, isTrue);
      expect(postCubit.state.isBookmarked, isTrue);
      expectForeground(tester, Colors.black);
      expect(
        Theme.of(tester.element(clientIcon(AppIcons.back)))
            .scaffoldBackgroundColor,
        Colors.white,
      );

      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();
      expect(find.byType(ThemeModeMenu), findsOneWidget);
      expectForeground(tester, Colors.black);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'System follows device changes; an explicit mode overrides them',
    (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        const ResponsiveConfig(
          child: MyApp(postsRepository: EmptyPostsRepository()),
        ),
      );
      await tester.pumpAndSettle();
      BuildContext currentContext() =>
          tester.element(find.byType(ThemeModeMenu));
      final cubit = currentContext().read<ThemeCubit>();
      expect(cubit.state, ThemeMode.system);
      expect(Theme.of(currentContext()).brightness, Brightness.dark);
      expectForeground(tester, Colors.white);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(Theme.of(currentContext()).brightness, Brightness.light);
      expectForeground(tester, Colors.black);

      cubit.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(Theme.of(currentContext()).brightness, Brightness.dark);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(Theme.of(currentContext()).brightness, Brightness.dark);

      cubit.useSystemTheme();
      await tester.pumpAndSettle();
      expect(Theme.of(currentContext()).brightness, Brightness.light);
      expectForeground(tester, Colors.black);
      expect(tester.takeException(), isNull);
    },
  );
}
