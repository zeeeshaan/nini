import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/widgets/address_dialog/address_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/alt_text_dialog/alt_text_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/features_dialog/features_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/post_type_dialog/post_type_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/preparation_time_dialog/preparation_time_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/schedule_post_dialog/schedule_post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/tags_dialog/tags_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/unit_dialog/unit_dialog.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class _OfflineTiles extends TileProvider {
  final image = MemoryImage(File('assets/img1.png').readAsBytesSync());
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      image;
}

Future<void> _open(
  WidgetTester tester,
  Widget dialog,
  ValueNotifier<ThemeMode> mode,
) async {
  await tester.pumpWidget(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: mode,
      builder: (_, value, _) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: value,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPostDialog<void>(context, dialog),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void _expectPalette(WidgetTester tester, ThemeMode pageMode) {
  final surface = tester.widget<Material>(
    find.byKey(const ValueKey('post-dialog-surface')),
  );
  final lightPage = pageMode == ThemeMode.light;
  final foreground = lightPage ? Colors.white : Colors.black;
  expect(surface.color, lightPage ? Colors.black : Colors.white);
  final sheet = tester.element(find.byType(PostDialog).last);
  expect(Theme.of(sheet).colorScheme.onSurface, foreground);
  expect(IconTheme.of(sheet).color, foreground);
  final parent = tester.element(find.text('open'));
  expect(
    Theme.of(parent).brightness,
    lightPage ? Brightness.light : Brightness.dark,
  );
  for (final icon in tester.widgetList<SvgPicture>(
    find.descendant(
      of: find.byType(PostDialog).last,
      matching: find.byType(SvgPicture),
    ),
  )) {
    expect(icon.colorFilter, ColorFilter.mode(foreground, BlendMode.srcIn));
    expect(icon.renderingStrategy.name, 'picture');
  }
  for (final image in tester.widgetList<Image>(
    find.descendant(
      of: find.byType(PostDialog).last,
      matching: find.byType(Image),
    ),
  )) {
    expect(image.color, foreground);
  }
  for (final element
      in find
          .descendant(
            of: find.byType(PostDialog).last,
            matching: find.byType(ElevatedButton),
          )
          .evaluate()) {
    final colors = Theme.of(element).colorScheme;
    final style = ElevatedButtonTheme.of(element).style!;
    expect(style.backgroundColor!.resolve({}), foreground);
    expect(style.foregroundColor!.resolve({}), colors.surface);
  }
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Create-post sheets use the opposite palette in $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final themeMode = ValueNotifier(mode);
      addTearDown(themeMode.dispose);
      final dialogs = <Widget>[
        const TypePostDialog(selected: CreatePostType.product),
        const PreparationTimeDialog(selected: PreparationTime.none),
        const UnitDialog(selected: PostUnit.piece),
        const AltTextDialog(attachments: [], initial: {}),
        const SchedulePostDialog(),
        const FeaturesDialog(initial: []),
        AddressDialog(tileProvider: _OfflineTiles()),
        const TagsDialog(initial: ['tag']),
      ];
      for (final dialog in dialogs) {
        await _open(tester, dialog, themeMode);
        _expectPalette(tester, mode);
        if (dialog is TagsDialog) {
          final icons = tester
              .widgetList<AppIcon>(find.byType(AppIcon))
              .map((e) => e.asset);
          expect(
            icons,
            containsAll([AppIcons.tag, AppIcons.add, AppIcons.close]),
          );
        }
        Navigator.of(tester.element(find.byType(PostDialog).last)).pop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'Open sheet follows app theme changes and keeps entered form data',
    (tester) async {
      final mode = ValueNotifier(ThemeMode.light);
      addTearDown(mode.dispose);
      await _open(tester, const FeaturesDialog(initial: []), mode);
      await tester.enterText(find.byType(TextField).last, 'feature draft');
      _expectPalette(tester, ThemeMode.light);
      mode.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      _expectPalette(tester, ThemeMode.dark);
      expect(find.text('feature draft'), findsOneWidget);
      mode.value = ThemeMode.light;
      await tester.pumpAndSettle();
      _expectPalette(tester, ThemeMode.light);
      expect(find.text('feature draft'), findsOneWidget);
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(PostDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
