import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_details_screen.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_gallery_screen.dart';
import 'package:nini/features/create_post/presentation/widgets/caption_editor/caption_editor.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_grid/gallery_grid.dart';
import 'package:nini/features/home/presentation/widgets/home_post_card/home_post_card.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/posts/data/local_posts_repository.dart';
import 'package:nini/features/posts/domain/posts_repository.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/widgets/published_post_content.dart';
import 'package:nini/main.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

base class DiskPickedFile extends PlatformFile {
  DiskPickedFile(this.file);
  final File file;
  @override
  String get name => p.basename(file.path);
  @override
  Uri get uri => file.uri;
  @override
  Stream<Uint8List> readAsByteStream() =>
      file.openRead().map(Uint8List.fromList);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class BrokenPickedFile extends DiskPickedFile {
  BrokenPickedFile(super.file);
  @override
  Stream<Uint8List> readAsByteStream() =>
      Stream.error(const FileSystemException('Unavailable'));
}

class GatedRepository implements PostsRepository {
  final publishResult = Completer<PostItem>();
  Completer<List<PostItem>>? initialLoad;
  PostDraft? receivedDraft;
  int calls = 0;
  @override
  Future<List<PostItem>> load() async =>
      initialLoad == null ? [] : initialLoad!.future;
  @override
  Future<PostItem> publish(
    PostDraft draft,
    List<GalleryAttachment> attachments,
  ) {
    calls++;
    receivedDraft = draft;
    return publishResult.future;
  }
}

PostDraft validDraft() => const PostDraft(
  postType: CreatePostType.product,
  title: 'My published item',
  caption: 'My actual caption',
  captionDelta: [
    {
      'insert': 'My actual caption',
      'attributes': {'bold': true},
    },
    {'insert': '\n'},
  ],
  price: '۲۰۰',
  discount: '25',
  warehouseStock: '3',
  features: [PostFeature(name: 'Material', value: 'Steel')],
  tags: ['handmade'],
);
PostItem published(PostDraft draft, File image) => PostItem(
  id: 'published_test',
  imageAsset: '',
  title: draft.title,
  category: AppStrings.product,
  stockCount: 3,
  price: '150',
  originalPrice: '200',
  publishedAt: DateTime.now(),
  media: [
    PostMedia(path: image.path, name: 'picked.png', type: PostMediaType.image),
  ],
  metadata: draft.toJson(),
);
Finder input(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is AppTextField && widget.label == label,
  ),
  matching: find.byType(EditableText),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File image;
  late GalleryAttachment attachment;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nini-post-test-');
    image = await File('assets/icons/general/heart.png')
        .copy(p.join(directory.path, 'picked.png'));
    attachment = GalleryAttachment.fromFile(DiskPickedFile(image));
  });
  tearDown(() async {
    AppToast.dismiss();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'Publish saves real media, rich content, prices and reloads after restart',
    () async {
      final repo = LocalPostsRepository(
        directoryProvider: () async => directory,
      );
      final result = await repo.publish(validDraft(), [attachment]);
      expect(result.title, 'My published item');
      expect(result.price, '150');
      expect(result.originalPrice, '200');
      expect(result.stockCount, 3);
      expect(result.media.single.path, isNot(image.path));
      expect(
        await File(result.media.single.path).readAsBytes(),
        await image.readAsBytes(),
      );
      await image
          .delete(); // Gallery/file-picker temporary data is no longer needed.
      final restored = await LocalPostsRepository(
        directoryProvider: () async => directory,
      ).load();
      expect(restored, hasLength(1));
      expect(await File(restored.single.media.single.path).exists(), isTrue);
      expect(restored.single.captionDelta.first['attributes'], {'bold': true});
      expect(restored.single.features, [('Material', 'Steel')]);
      expect(restored.single.metadata['tags'], ['handmade']);
      final index = jsonDecode(
        await File(p.join(directory.path, 'nini_posts', 'posts.json'))
            .readAsString(),
      ) as Map;
      expect(
        p.isRelative(index['posts'][0]['media'][0]['path'] as String),
        isTrue,
      );
    },
  );

  test(
    'iOS Documents uses the app sandbox rather than a new native plugin',
    () {
      final documents = LocalPostsRepository.iosDocumentsDirectory(
        Directory(
          '/private/var/mobile/Containers/Data/Application/example/tmp',
        ),
      );
      expect(
        documents.path,
        '/private/var/mobile/Containers/Data/Application/example/Documents',
      );
    },
  );

  test(
    'Gallery original export is saved when its preview file export fails',
    () async {
      const channel = MethodChannel('com.fluttercandies/photo_manager');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getFullFile') {
          if ((call.arguments as Map)['isOrigin'] == true) return image.path;
          throw PlatformException(
            code: 'export_failed',
            message: 'Preview export unavailable',
          );
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final repo = LocalPostsRepository(
        directoryProvider: () async => directory,
      );
      final galleryPhoto = GalleryAttachment.fromAsset(
        AssetEntity(
          id: 'gallery-photo',
          typeInt: 1,
          width: 26,
          height: 26,
          title: 'photo.png',
        ),
      );
      final post = await repo.publish(validDraft(), [galleryPhoto]);
      expect(
        await File(post.media.single.path).readAsBytes(),
        await image.readAsBytes(),
      );
      expect((await repo.load()).single.id, post.id);
    },
  );

  test('A second publish preserves older posts and a failed copy leaves no partial post', () async {
    final repo = LocalPostsRepository(directoryProvider: () async => directory);
    final first = await repo.publish(validDraft(), [attachment]);
    final second = await repo.publish(validDraft().copyWith(title: 'Second'), [
      attachment,
    ]);
    expect((await repo.load()).map((post) => post.id), [second.id, first.id]);
    final before = await File(
      p.join(directory.path, 'nini_posts', 'posts.json'),
    ).readAsString();
    await expectLater(
      repo.publish(validDraft(), [
        attachment,
        GalleryAttachment.fromFile(BrokenPickedFile(image)),
      ]),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      await File(p.join(directory.path, 'nini_posts', 'posts.json'))
          .readAsString(),
      before,
    );
    final entries = await Directory(p.join(directory.path, 'nini_posts'))
        .list()
        .toList();
    expect(entries.whereType<Directory>(), hasLength(2));
    expect(
      entries.where((entry) => p.basename(entry.path).startsWith('.pending')),
      isEmpty,
    );
  });

  test(
    'Invalid input or an unreadable post index is never reported as published',
    () async {
      final repo = LocalPostsRepository(
        directoryProvider: () async => directory,
      );
      await expectLater(
        repo.publish(validDraft().copyWith(discount: '101'), [attachment]),
        throwsA(isA<PostPublishException>()),
      );
      final root = await Directory(p.join(directory.path, 'nini_posts'))
          .create();
      final index = await File(p.join(root.path, 'posts.json'))
          .writeAsString('corrupted');
      await expectLater(
        repo.publish(validDraft(), [attachment]),
        throwsFormatException,
      );
      expect(await index.readAsString(), 'corrupted');
    },
  );

  test('Startup loading cannot overwrite a publish or let a second publish through', () async {
    final repo = GatedRepository()..initialLoad = Completer<List<PostItem>>();
    final cubit = PostsCubit(repo);
    addTearDown(cubit.close);
    final load = cubit.load();
    final first = cubit.publish(validDraft(), [attachment]);
    expect(await cubit.publish(validDraft(), [attachment]), isNull);
    repo.initialLoad!.complete([]);
    await load;
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isPublishing, isTrue);
    expect(repo.calls, 1);
    final post = published(validDraft(), image);
    repo.publishResult.complete(post);
    expect(await first, post);
    expect(cubit.state.posts.first.id, post.id);
    expect(cubit.state.posts, hasLength(10));
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'Publish shows a loader, closes both create routes, and opens the real post in $mode',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = GatedRepository();
        await tester.pumpWidget(
          ResponsiveConfig(
            child: MyApp(initialThemeMode: mode, postsRepository: repo),
          ),
        );
        await tester.pumpAndSettle();
        final create = find
            .byWidgetPredicate(
              (widget) => widget is AppIcon && widget.asset == AppIcons.add,
            )
            .last;
        await tester.tap(create);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        // Supply a selected file without invoking a real OS picker in a widget test.
        final gallery = tester
            .element(find.byType(GalleryGrid))
            .read<GalleryCubit>();
        gallery.emit(
          gallery.state.copyWith(
            status: GalleryStatus.ready,
            selected: [attachment],
            errorMessage: null,
          ),
        );
        AppToast.dismiss();
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.next));
        await tester.pumpAndSettle();
        expect(find.byType(CreatePostDetailsScreen), findsOneWidget);
        expect(find.text(AppStrings.next), findsNothing);
        final draft = tester
            .element(find.byType(CreatePostDetailsScreen))
            .read<CreatePostCubit>();
        draft.selectPostType(CreatePostType.product);
        await tester.ensureVisible(input(AppStrings.productServiceTitle));
        await tester.enterText(
          input(AppStrings.productServiceTitle),
          'My published item',
        );
        final editor = tester.widget<CaptionEditor>(find.byType(CaptionEditor));
        editor.controller.document.insert(0, 'My actual caption');
        editor.controller.updateSelection(
          const TextSelection(baseOffset: 0, extentOffset: 17),
          quill.ChangeSource.local,
        );
        editor.controller.formatSelection(quill.Attribute.bold);
        draft.setFeatures([
          const PostFeature(name: 'Material', value: 'Steel'),
        ]);
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.publish));
        await tester.pump();
        expect(find.text(AppStrings.publishing), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(repo.calls, 1);
        expect(
          tester
              .widget<AppButton>(
                find.widgetWithText(AppButton, AppStrings.cancel),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.text(AppStrings.publishing));
        expect(repo.calls, 1);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.byType(CreatePostDetailsScreen), findsOneWidget);
        repo.publishResult.complete(published(repo.receivedDraft!, image));
        await tester.pumpAndSettle();
        expect(find.byType(CreatePostDetailsScreen), findsNothing);
        expect(find.byType(CreatePostGalleryScreen), findsNothing);
        expect(find.text('My published item'), findsOneWidget);
        expect(
          tester.widget<HomePostCard>(find.byType(HomePostCard).first).post.id,
          'published_test',
        );
        await tester.tap(find.text('My published item'));
        await tester.pumpAndSettle();
        expect(find.byType(PostDetailScreen), findsOneWidget);
        expect(find.byType(PublishedPostContent), findsOneWidget);
        expect(find.text('Steel'), findsOneWidget);
        expect(find.text(AppStrings.postTitle), findsNothing);
        final contentEditor = tester.widget<quill.QuillEditor>(
          find.byType(quill.QuillEditor),
        );
        expect(
          contentEditor.controller.document.toPlainText(),
          'My actual caption\n',
        );
        expect(
          contentEditor.controller.document
              .toDelta()
              .toJson()
              .first['attributes'],
          {'bold': true},
        );
        expect(contentEditor.controller.readOnly, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('A save failure keeps the draft and lets the user retry', (
    tester,
  ) async {
    final repo = GatedRepository();
    final posts = PostsCubit(repo);
    final draft = CreatePostCubit()
      ..selectPostType(CreatePostType.product)
      ..updateTitle('Kept title')
      ..updateCaption('Kept caption');
    addTearDown(posts.close);
    addTearDown(draft.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: posts),
          BlocProvider.value(value: draft),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: CreatePostDetailsScreen(attachments: [attachment]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.publish));
    await tester.pump();
    repo.publishResult.completeError(const FileSystemException('No space'));
    await tester.pumpAndSettle();
    expect(find.byType(CreatePostDetailsScreen), findsOneWidget);
    expect(find.text(AppStrings.publish), findsOneWidget);
    expect(find.text(AppStrings.publishing), findsNothing);
    expect(draft.state.title, 'Kept title');
    expect(draft.state.caption, 'Kept caption');
    expect(posts.state.posts, hasLength(9));
    expect(posts.state.publishError, contains('پیش‌نویس شما محفوظ است'));
    expect(tester.takeException(), isNull);
    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
