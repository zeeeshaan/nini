import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_details_screen.dart';
import 'package:nini/features/create_post/presentation/widgets/address_dialog/address_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/address_dialog/location_map.dart';
import 'package:nini/features/create_post/presentation/widgets/alt_text_dialog/alt_text_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/caption_editor/caption_editor.dart';
import 'package:nini/features/create_post/presentation/widgets/features_dialog/features_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/post_type_dialog/post_type_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/preparation_time_dialog/preparation_time_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/schedule_post_dialog/schedule_post_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/tags_dialog/tags_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/unit_dialog/unit_dialog.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

final class TestDocument extends PlatformFile {
  @override
  String get name => 'notes.pdf';
  @override
  Uri get uri => Uri.file('/tmp/notes.pdf');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MemoryTiles extends TileProvider {
  final image = MemoryImage(
    File('assets/icons/general/heart.png').readAsBytesSync(),
  );
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      image;
}

Future<void> openSheet(
  WidgetTester tester,
  Widget child, {
  ThemeMode mode = ThemeMode.light,
  ValueChanged<Object?>? result,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final value = await showPostDialog<Object>(context, child);
              result?.call(value);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is AppTextField && widget.label == label,
  ),
  matching: find.byType(EditableText),
);

void main() {
  test(
    'All draft options serialize, preserve formatting, and clear schedules',
    () {
      final cubit = CreatePostCubit();
      addTearDown(cubit.close);
      cubit.updateTitle('Title');
      cubit.updateRichCaption('Hello', [
        {
          'insert': 'Hello',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
      cubit.selectPreparationTime(PreparationTime.threeDays);
      cubit.selectUnit(PostUnit.hour);
      cubit.selectInventoryStatus(InventoryStatus.preOrder);
      cubit.setFeatures([const PostFeature(name: 'Color', value: 'Black')]);
      cubit.setTags(['handmade']);
      cubit.setAltTexts({'asset:1': 'A handmade bag'});
      final start = DateTime.now().add(const Duration(days: 2));
      cubit.setSchedule(
        PostSchedule(
          startsAt: start,
          endsAt: start.add(const Duration(hours: 1)),
        ),
      );
      final snapshot = cubit.state;
      cubit.updatePrice('200');
      expect(cubit.state.captionDelta.first['attributes'], {'bold': true});
      final json = cubit.state.toJson();
      expect(json['preparationDays'], 3);
      expect(json['unit'], 'hour');
      expect(jsonEncode(json), contains('startsAt'));
      cubit.setSchedule(null);
      expect(cubit.state.schedule, isNull);
      expect(snapshot.schedule, isNotNull);
      expect(
        () => cubit.state.features.add(
          const PostFeature(name: 'Size', value: 'S'),
        ),
        throwsUnsupportedError,
      );
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Separate choice sheets return selected values in $mode', (
      tester,
    ) async {
      Object? selected;
      await openSheet(
        tester,
        const TypePostDialog(selected: CreatePostType.product),
        mode: mode,
        result: (value) => selected = value,
      );
      await tester.tap(find.text(AppStrings.services));
      await tester.pumpAndSettle();
      expect(selected, CreatePostType.services);
      await openSheet(
        tester,
        const PreparationTimeDialog(selected: PreparationTime.none),
        mode: mode,
        result: (value) => selected = value,
      );
      await tester.tap(find.text(PreparationTime.threeDays.label));
      await tester.pumpAndSettle();
      expect(selected, PreparationTime.threeDays);
      await openSheet(
        tester,
        const UnitDialog(selected: PostUnit.piece),
        mode: mode,
        result: (value) => selected = value,
      );
      await tester.tap(find.text(AppStrings.unitHour));
      await tester.pumpAndSettle();
      expect(selected, PostUnit.hour);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Features validate, edit, remove, and save in $mode', (
      tester,
    ) async {
      Object? result;
      await openSheet(
        tester,
        const FeaturesDialog(initial: []),
        mode: mode,
        result: (value) => result = value,
      );
      await tester.tap(find.byTooltip(AppStrings.addFeature));
      await tester.pump();
      expect(find.text(AppStrings.featureAndValueRequired), findsOneWidget);
      await tester.enterText(field(AppStrings.feature), 'Assembly Required');
      await tester.enterText(field(AppStrings.featureValue), 'No');
      await tester.tap(find.byTooltip(AppStrings.addFeature));
      await tester.pump();
      await tester.tap(find.text('Assembly Required'));
      await tester.pump();
      await tester.enterText(field(AppStrings.featureValue), 'Yes');
      await tester.tap(find.byTooltip(AppStrings.saveFeature));
      await tester.pump();
      expect(find.text('Yes'), findsOneWidget);
      await tester.enterText(field(AppStrings.feature), 'Color');
      await tester.enterText(field(AppStrings.featureValue), 'Red');
      await tester.tap(find.byTooltip(AppStrings.addFeature));
      await tester.pump();
      await tester.tap(find.byTooltip(AppStrings.removeFeature('Color')));
      await tester.pump();
      await tester.tap(find.text(AppStrings.done));
      await tester.pumpAndSettle();
      final features = result! as List<PostFeature>;
      expect(features, hasLength(1));
      expect(features.single.value, 'Yes');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Time range crosses midnight and rejects past dates in $mode', (
      tester,
    ) async {
      Object? result;
      final tomorrow = DateUtils.dateOnly(
        DateTime.now().add(const Duration(days: 1)),
      );
      final initial = PostSchedule(
        startsAt: tomorrow.add(const Duration(hours: 10)),
        endsAt: tomorrow.add(const Duration(hours: 11)),
      );
      await openSheet(
        tester,
        SchedulePostDialog(initial: initial),
        mode: mode,
        result: (value) => result = value,
      );
      final calendar = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      calendar.onDateChanged(DateUtils.dateOnly(DateTime.now()));
      await tester.tap(find.text(AppStrings.time));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .onDateTimeChanged(DateTime(2026, 1, 1));
      await tester.pump();
      await tester.tap(find.text(AppStrings.add));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.futureTimeRequired), findsOneWidget);
      await tester.tap(find.text(AppStrings.calendar));
      await tester.pumpAndSettle();
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(tomorrow);
      await tester.tap(find.text(AppStrings.time));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .onDateTimeChanged(tomorrow.add(const Duration(hours: 23)));
      await tester.tap(find.text(AppStrings.timeTo));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .onDateTimeChanged(tomorrow.add(const Duration(hours: 1)));
      await tester.pump();
      await tester.tap(find.text(AppStrings.add));
      await tester.pumpAndSettle();
      final schedule = (result! as ScheduleSelection).schedule!;
      expect(
        schedule.endsAt.difference(schedule.startsAt),
        const Duration(hours: 2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Address sheet saves a map pin and does not invent an address in $mode',
      (tester) async {
        Object? result;
        await openSheet(
          tester,
          AddressDialog(tileProvider: MemoryTiles()),
          mode: mode,
          result: (value) => result = value,
        );
        await tester.tap(find.text(AppStrings.done));
        await tester.pump();
        expect(find.text(AppStrings.addressPinRequired), findsOneWidget);
        await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          tester.widget<LocationMap>(find.byType(LocationMap)).point,
          isNotNull,
        );
        await tester.enterText(field(AppStrings.address), 'My address');
        await tester.tap(find.text(AppStrings.done));
        await tester.pumpAndSettle();
        final address = result! as AddressSelection;
        expect(address.selected.address, 'My address');
        expect(
          address.selected.latitude,
          closeTo(LocationMap.defaultCenter.latitude, .01),
        );
        expect(address.saved, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Cancel discards feature edits; tags normalize; alt text saves per attachment',
    (tester) async {
      Object? result;
      final original = [const PostFeature(name: 'Color', value: 'Blue')];
      await openSheet(
        tester,
        FeaturesDialog(initial: original),
        result: (value) => result = value,
      );
      await tester.tap(find.byTooltip(AppStrings.removeFeature('Color')));
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(original, hasLength(1));
      await openSheet(
        tester,
        const TagsDialog(initial: []),
        result: (value) => result = value,
      );
      await tester.enterText(field(AppStrings.keywords), '#Bag,bag, Handmade');
      await tester.tap(find.text(AppStrings.done));
      await tester.pumpAndSettle();
      expect(result, ['Bag', 'Handmade']);
      final attachment = GalleryAttachment.fromFile(TestDocument());
      await openSheet(
        tester,
        AltTextDialog(attachments: [attachment], initial: const {}),
        result: (value) => result = value,
      );
      await tester.enterText(
        find.byType(EditableText),
        'Instructions for using the product',
      );
      await tester.tap(find.text(AppStrings.done));
      await tester.pumpAndSettle();
      expect(result, {attachment.id: 'Instructions for using the product'});
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Caption toolbar formatting and contrast in $mode', (
      tester,
    ) async {
      final controller = quill.QuillController(
        document: quill.Document()..insert(0, 'Hello caption'),
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Scaffold(body: CaptionEditor(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('توپر'));
      await tester.pumpAndSettle();
      expect(
        IconTheme.of(
          tester.element(
            find.byWidgetPredicate(
              (widget) => widget is AppIcon && widget.asset == AppIcons.bold,
            ),
          ),
        ).color,
        mode == ThemeMode.dark ? Colors.black : Colors.white,
      );
      expect(
        controller.document.toDelta().toJson().first['attributes'],
        containsPair('bold', true),
      );
      await tester.tap(find.byTooltip('مورب'));
      await tester.pump();
      expect(
        controller.document.toDelta().toJson().first['attributes'],
        containsPair('italic', true),
      );
      final restored = quill.Document.fromJson(
        controller.document.toDelta().toJson(),
      );
      expect(restored.toDelta().toJson().first['attributes'], {
        'bold': true,
        'italic': true,
      });
      await tester.ensureVisible(find.byTooltip('زیرخط'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('زیرخط'));
      await tester.pump();
      expect(
        controller.document.toDelta().toJson().first['attributes'],
        containsPair('underline', true),
      );
      await tester.ensureVisible(find.byTooltip('لیست نقطه‌ای'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('لیست نقطه‌ای'));
      await tester.pump();
      expect(
        controller.document.toDelta().toJson().last['attributes'],
        containsPair('list', 'bullet'),
      );
      await tester.ensureVisible(find.byTooltip(AppStrings.undo));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.undo));
      await tester.pump();
      expect(controller.document.toDelta().toJson().last['attributes'], isNull);
      await tester.ensureVisible(find.byTooltip(AppStrings.redo));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.redo));
      await tester.pump();
      expect(
        controller.document.toDelta().toJson().last['attributes'],
        containsPair('list', 'bullet'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'Feature sheet keeps actions visible above a small-screen keyboard',
    (tester) async {
      await openSheet(tester, const FeaturesDialog(initial: []));
      tester.view.physicalSize = const Size(320, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(field(AppStrings.feature), 'Material');
      await tester.enterText(field(AppStrings.featureValue), 'Steel');
      await tester.tap(find.byTooltip(AppStrings.addFeature));
      await tester.pumpAndSettle();
      expect(find.text('Steel'), findsOneWidget);
      expect(
        tester.getBottomRight(find.text(AppStrings.done)).dy,
        lessThan(360),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Details screen opens separate dialogs and restores formatted caption',
    (tester) async {
      final cubit = CreatePostCubit()
        ..updateRichCaption('Formatted', [
          {
            'insert': 'Formatted',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ]);
      addTearDown(cubit.close);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: BlocProvider.value(
            value: cubit,
            child: const CreatePostDetailsScreen(attachments: []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final editor = tester.widget<CaptionEditor>(find.byType(CaptionEditor));
      expect(
        editor.controller.document.toDelta().toJson().first['attributes'],
        {'bold': true},
      );
      editor.controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 9),
        quill.ChangeSource.local,
      );
      editor.controller.formatSelection(quill.Attribute.italic);
      await tester.pump();
      expect(cubit.state.caption, 'Formatted');
      expect(
        cubit.state.captionDelta.first['attributes'],
        containsPair('italic', true),
      );
      await tester.ensureVisible(find.text(AppStrings.postType));
      await tester.tap(find.text(AppStrings.postType));
      await tester.pumpAndSettle();
      expect(find.byType(TypePostDialog), findsOneWidget);
      await tester.tap(find.text(AppStrings.product));
      await tester.pumpAndSettle();
      expect(cubit.state.postType, CreatePostType.product);
      await tester.ensureVisible(find.text(AppStrings.preparationTime));
      await tester.tap(find.text(AppStrings.preparationTime));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PreparationTime.twoDays.label));
      await tester.pumpAndSettle();
      expect(cubit.state.preparationTime, PreparationTime.twoDays);
      expect(cubit.state.captionDelta.first['attributes'], {
        'bold': true,
        'italic': true,
      });
      expect(tester.takeException(), isNull);
    },
  );
}
