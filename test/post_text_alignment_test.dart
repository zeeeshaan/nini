import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_details_screen.dart';
import 'package:nini/features/create_post/presentation/widgets/form/caption_editor.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/posts/presentation/pages/edit_post_screen.dart';
import 'package:nini/features/posts/presentation/widgets/common/published_post_content.dart';
import 'package:nini/shared/models/post/post_item.dart';

class _Categories extends ProfileCategoriesRepository {
  @override
  Future<List<ProfileCategory>> load() async => [];
  @override
  Future<ProfileCategory> create(String name) => throw UnimplementedError();
  @override
  Future<ProfileCategory> rename(String id, String name) =>
      throw UnimplementedError();
  @override
  Future<void> delete(String id) => throw UnimplementedError();
}

PostItem _post({bool rich = true}) => PostItem(
  id: 'alignment-post',
  imageAsset: 'assets/img1.png',
  title: 'Post title',
  category: 'Product',
  stockCount: 2,
  price: '12000',
  originalPrice: '',
  media: const [
    PostMedia(
      path: 'assets/img1.png',
      name: 'Photo',
      type: PostMediaType.image,
      source: PostMediaSource.asset,
    ),
  ],
  details: PostDetails(
    caption: 'Bold caption text',
    captionDelta: rich
        ? const [
            {
              'insert': 'Bold',
              'attributes': {'bold': true},
            },
            {'insert': ' caption text'},
            {
              'insert': '\n',
              'attributes': {'align': 'left'},
            },
          ]
        : const [],
    unit: PostUnit.piece,
    features: const [PostFeature(name: 'Material', value: 'Metal')],
  ),
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [
    ...GlobalMaterialLocalizations.delegates,
    quill.FlutterQuillLocalizations.delegate,
  ],
  home: Scaffold(body: SizedBox(width: 390, child: child)),
);

Future<void> _openEditor(WidgetTester tester, PostItem post) async {
  final categories = ProfileCategoriesCubit(_Categories());
  await categories.load();
  addTearDown(categories.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: categories,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          quill.FlutterQuillLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EditPostScreen(post: post),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open editor'));
  await tester.pumpAndSettle();
}

void main() {
  for (final rich in [false, true]) {
    testWidgets(
      'Create Post right-aligns ${rich ? 'existing rich' : 'new'} captions and field labels without changing English input or losing formatting',
      (tester) async {
        final initial = PostDraft(
          postType: CreatePostType.product,
          title: 'English title',
          caption: rich ? _post().caption : '',
          captionDelta: rich ? _post().captionDelta : const [],
        );
        final draft = CreatePostCubit(initial: initial);
        final categories = ProfileCategoriesCubit(_Categories());
        await categories.load();
        addTearDown(draft.close);
        addTearDown(categories.close);
        final before = jsonEncode(draft.state.toJson());
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: draft),
              BlocProvider.value(value: categories),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const CreatePostDetailsScreen(attachments: []),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final editor = find.byType(CaptionEditor);
        final controller = tester.widget<CaptionEditor>(editor).controller;
        expect(controller.document.hasUndo, isFalse);
        expect(jsonEncode(draft.state.toJson()), before);
        final firstLine = rich ? initial.caption : 'A new caption';
        final insert = rich
            ? '\nAnother caption line'
            : '$firstLine\nAnother caption line';
        final offset = controller.document.length - 1;
        controller.replaceText(
          offset,
          0,
          insert,
          TextSelection.collapsed(offset: offset + insert.length),
        );
        await tester.pumpAndSettle();
        expect(draft.state.caption, '$firstLine\nAnother caption line');
        final delta = controller.document.toDelta().toJson();
        final paragraphs = delta.where(
          (op) => (op['insert'] as String).contains('\n'),
        );
        expect(paragraphs, isNotEmpty);
        for (final paragraph in paragraphs) {
          expect(paragraph['attributes']['align'], 'right');
        }
        if (rich) expect(delta.first['attributes']['bold'], isTrue);
        await tester.ensureVisible(editor);
        await tester.pumpAndSettle();
        final line = find.descendant(
          of: find.byType(quill.QuillEditor),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains(firstLine),
          ),
        );
        final paragraph = tester.renderObject<RenderParagraph>(line);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: firstLine.length),
        );
        final right = boxes
            .map((box) => box.right)
            .reduce((a, b) => a > b ? a : b);
        expect(
          paragraph.localToGlobal(Offset(right, 0)).dx,
          closeTo(tester.getRect(editor).right - 12, 2),
        );
        for (final entry in {
          CreatePostStrings.productServiceTitle: 'Updated English title',
          CreatePostStrings.price: '12000',
          CreatePostStrings.discount: '20',
          CreatePostStrings.warehouseStock: '5',
        }.entries) {
          final field = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.labelText == entry.key,
          );
          await tester.ensureVisible(field);
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.text(entry.key)).center.dx,
            greaterThan(tester.getRect(field).center.dx),
          );
          expect(
            tester.widget<TextField>(field).textDirection,
            TextDirection.ltr,
          );
          await tester.enterText(field, entry.value);
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(field).controller!.text, entry.value);
        }
        expect(draft.state.title, 'Updated English title');
        expect(draft.state.price, '12000');
        expect(draft.state.discount, '20');
        expect(draft.state.warehouseStock, '5');
        expect(draft.state.caption, '$firstLine\nAnother caption line');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final rich in [false, true]) {
    testWidgets(
      'published ${rich ? 'rich' : 'plain'} caption aligns right without changing stored content',
      (tester) async {
        final post = _post(rich: rich);
        final original = jsonEncode(post.toJson());
        await tester.pumpWidget(_app(PublishedPostContent(post: post)));
        await tester.pumpAndSettle();
        final controller = tester
            .widget<quill.QuillEditor>(find.byType(quill.QuillEditor))
            .controller;
        expect(controller.readOnly, isTrue);
        expect(controller.document.toPlainText().trim(), post.caption);
        final delta = controller.document.toDelta().toJson();
        expect(delta.last['attributes']['align'], 'right');
        if (rich) expect(delta.first['attributes']['bold'], isTrue);
        final text = find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Bold caption text'),
        );
        expect(text, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: post.caption.length),
        );
        final rightEdge = boxes.fold<double>(
          0,
          (right, box) => right > box.right ? right : box.right,
        );
        expect(
          paragraph.localToGlobal(Offset(rightEdge, 0)).dx,
          closeTo(
            tester.getRect(find.byType(PublishedPostContent)).right - 22,
            1,
          ),
        );
        expect(jsonEncode(post.toJson()), original);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Edit Post field labels, values and dropdowns align right', (
    tester,
  ) async {
    await _openEditor(tester, _post());
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.length, greaterThan(5));
    for (final field in fields) {
      expect(field.textAlign, TextAlign.right);
    }
    final decorators = find.byWidgetPredicate(
      (w) => w is InputDecorator && w.decoration.labelText != null,
    );
    expect(decorators, findsWidgets);
    for (final element in decorators.evaluate()) {
      expect(Directionality.of(element), TextDirection.rtl);
    }
    await tester.ensureVisible(find.text(ProfilePostStrings.product).first);
    await tester.pumpAndSettle();
    final selected = tester.getRect(
      find.text(ProfilePostStrings.product).first,
    );
    final input = tester.getRect(
      find
          .ancestor(
            of: find.text(ProfilePostStrings.product).first,
            matching: find.byType(InputDecorator),
          )
          .first,
    );
    expect(selected.center.dx, greaterThan(input.center.dx));
    final controller = tester
        .widget<CaptionEditor>(find.byType(CaptionEditor))
        .controller;
    final delta = controller.document.toDelta().toJson();
    expect(delta.last['attributes']['align'], 'right');
    expect(delta.first['attributes']['bold'], isTrue);
    expect(controller.document.hasUndo, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opening and canceling Edit Post does not dirty or change a post',
    (tester) async {
      final post = _post();
      final before = jsonEncode(post.toJson());
      await _openEditor(tester, post);
      await tester.tap(find.text(ProfilePostStrings.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(EditPostScreen), findsNothing);
      expect(find.text(ProfilePostStrings.unsavedTitle), findsNothing);
      expect(find.text('Open editor'), findsOneWidget);
      expect(jsonEncode(post.toJson()), before);
    },
  );

  testWidgets(
    'editing a right-aligned field preserves the entered English text',
    (tester) async {
      await _openEditor(tester, _post());
      final title = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == ProfilePostStrings.title,
      );
      await tester.ensureVisible(title);
      await tester.pumpAndSettle();
      await tester.enterText(title, 'Updated English title');
      final state = tester.element(title).read<CreatePostCubit>().state;
      expect(state.title, 'Updated English title');
      expect(tester.widget<TextField>(title).textDirection, TextDirection.ltr);
      expect(tester.widget<TextField>(title).textAlign, TextAlign.right);
      expect(tester.takeException(), isNull);
    },
  );
}
