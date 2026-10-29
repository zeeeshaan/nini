import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/chat/data/device_chat_camera.dart';
import 'package:nini/features/chat/data/in_memory_chat_repository.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/domain/models/chat_message.dart';
import 'package:nini/features/chat/presentation/cubit/conversation_cubit.dart';
import 'package:nini/features/chat/presentation/helpers/chat_message_labels.dart';
import 'package:nini/features/chat/presentation/pages/conversation_screen.dart';
import 'package:nini/features/chat/presentation/widgets/attachment_sheet/chat_attachment_sheet.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_gallery_screen.dart';
import 'package:nini/features/create_post/presentation/widgets/address_dialog/address_dialog.dart';

import 'support/chat_fakes.dart';

class PreviewAsset extends AssetEntity {
  PreviewAsset(String id)
    : super(
        id: id,
        typeInt: 1,
        width: 146,
        height: 146,
        title: 'photo.png',
        mimeType: 'image/png',
      );
  static final bytes = File('assets/img2.png').readAsBytesSync();
  @override
  Future<Uint8List?> thumbnailDataWithOption(
    ThumbnailOption option, {
    PMProgressHandler? progressHandler,
    PMCancelToken? cancelToken,
  }) async => bytes;
}

class PreviewGallery extends GalleryCubit {
  PreviewGallery({this.status = GalleryStatus.ready, this.assets = const []});
  final GalleryStatus status;
  final List<AssetEntity> assets;
  @override
  Future<void> load() async =>
      emit(GalleryState(status: status, assets: assets));
}

class CapturingStore extends FakeChatMediaStore {
  List<GalleryAttachment> picked = [];
  @override
  Future<List<ChatAttachment>> prepare(List<GalleryAttachment> selected) async {
    picked = selected;
    return [
      const ChatAttachment(
        path: 'assets/img2.png',
        name: 'photo.png',
        type: ChatAttachmentType.image,
        sizeBytes: 100,
      ),
    ];
  }
}

ChatConversation get contact => ChatConversation(
  id: 'attachments',
  name: 'Contact',
  lastMessage: '',
  lastMessageAt: DateTime(2026),
);

Future<void> openChat(
  WidgetTester tester,
  InMemoryChatRepository repo, {
  bool dark = false,
  double width = 390,
  PreviewGallery? gallery,
  Future<GalleryAttachment?> Function()? capturePhoto,
  CapturingStore? store,
}) async {
  tester.view.physicalSize = Size(width, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: ConversationScreen(
        conversation: contact,
        repository: repo,
        voiceRecorder: FakeVoiceRecorder(),
        audioPlayer: FakeChatAudioPlayer(),
        mediaStore: store ?? CapturingStore(),
        capturePhoto: capturePhoto,
        galleryFactory: () => gallery ?? PreviewGallery(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0]) {
      testWidgets(
        'Paperclip sheet selects real gallery tiles at $width, dark=$dark',
        (tester) async {
          final repo = InMemoryChatRepository.empty(), store = CapturingStore();
          final gallery = PreviewGallery(
            assets: [PreviewAsset('one'), PreviewAsset('two')],
          );
          await openChat(
            tester,
            repo,
            dark: dark,
            width: width,
            gallery: gallery,
            store: store,
          );
          await tester.enterText(find.byType(TextField), 'draft');
          await tester.tap(find.byTooltip(AppStrings.attachFile));
          await tester.pumpAndSettle();
          expect(find.byType(ChatAttachmentSheet), findsOneWidget);
          for (final label in [
            AppStrings.document,
            AppStrings.location,
            AppStrings.camera,
            AppStrings.gallery,
          ]) {
            expect(find.text(label), findsOneWidget);
          }
          final grid = tester.widget<GridView>(find.byType(GridView));
          expect(
            (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
                .crossAxisCount,
            4,
          );
          await tester.tap(find.byType(AssetEntityImage).first);
          await tester.pump();
          expect(
            find.text(AppStrings.sendSelectedAttachments(1)),
            findsOneWidget,
          );
          await tester.tap(find.byType(AssetEntityImage).last);
          await tester.pump();
          await tester.tap(find.text(AppStrings.sendSelectedAttachments(2)));
          await tester.pumpAndSettle();
          expect(find.byType(ChatAttachmentSheet), findsNothing);
          expect(find.byType(CreatePostGalleryScreen), findsNothing);
          expect(store.picked.map((e) => e.asset!.id), ['one', 'two']);
          expect(
            repo.getMessages('attachments').single.attachment!.type,
            ChatAttachmentType.image,
          );
          expect(find.text('draft'), findsOneWidget);
          expect(gallery.isClosed, isTrue);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }

  for (final action in [
    ChatAttachmentAction.document,
    ChatAttachmentAction.gallery,
  ]) {
    testWidgets('$action opens the existing full gallery on the correct tab', (
      tester,
    ) async {
      const channel = MethodChannel('com.fluttercandies/photo_manager');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => 0,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final repo = InMemoryChatRepository.empty();
      await openChat(tester, repo);
      await tester.tap(find.byTooltip(AppStrings.attachFile));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          action == ChatAttachmentAction.document
              ? AppStrings.document
              : AppStrings.gallery,
        ),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<CreatePostGalleryScreen>(
        find.byType(CreatePostGalleryScreen),
      );
      expect(
        screen.initialTab,
        action == ChatAttachmentAction.document
            ? GalleryTab.file
            : GalleryTab.photo,
      );
      expect(screen.nextLabel, AppStrings.sendMessage);
      Navigator.of(tester.element(find.byType(CreatePostGalleryScreen))).pop();
      await tester.pumpAndSettle();
      expect(repo.getMessages('attachments'), isEmpty);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  for (final outcome in ['photo', 'cancel', 'denied']) {
    testWidgets('Camera $outcome returns safely to chat', (tester) async {
      final repo = InMemoryChatRepository.empty(), store = CapturingStore();
      await openChat(
        tester,
        repo,
        store: store,
        capturePhoto: () async {
          if (outcome == 'denied') {
            throw PlatformException(code: 'camera_access_denied');
          }
          return outcome == 'cancel'
              ? null
              : GalleryAttachment.fromFile(
                  CameraPhotoFile(XFile('assets/img2.png')),
                );
        },
      );
      await tester.tap(find.byTooltip(AppStrings.attachFile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.camera));
      await tester.pumpAndSettle();
      expect(find.byType(ChatAttachmentSheet), findsNothing);
      expect(
        repo.getMessages('attachments'),
        hasLength(outcome == 'photo' ? 1 : 0),
      );
      if (outcome == 'photo') {
        expect(store.picked.single.file!.name, 'img2.png');
      }
      if (outcome == 'denied') {
        expect(find.text(AppStrings.cameraAccessDenied), findsOneWidget);
      }
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Location reuses address picker and sends selected coordinates', (
    tester,
  ) async {
    final repo = InMemoryChatRepository.empty();
    await openChat(tester, repo);
    await tester.tap(find.byTooltip(AppStrings.attachFile));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.location));
    await tester.pumpAndSettle();
    expect(find.byType(AddressDialog), findsOneWidget);
    expect(find.text(AppStrings.sendLocation), findsOneWidget);
    const address = PostAddress(
      address: 'Tehran',
      latitude: 35.7,
      longitude: 51.4,
    );
    Navigator.of(tester.element(find.byType(AddressDialog)))
        .pop(const AddressSelection(selected: address, saved: [address]));
    await tester.pumpAndSettle();
    final message = repo.getMessages('attachments').single;
    expect(message.location!.address, 'Tehran');
    expect(message.location!.latitude, 35.7);
    expect(chatMessagePreview(message), AppStrings.location);
    expect(find.text(AppStrings.openLocation), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Denied gallery still allows options and dismissal preserves draft',
    (tester) async {
      final repo = InMemoryChatRepository.empty();
      final gallery = PreviewGallery(status: GalleryStatus.denied);
      await openChat(tester, repo, gallery: gallery);
      await tester.enterText(find.byType(TextField), 'unsent');
      await tester.tap(find.byTooltip(AppStrings.attachFile));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.galleryAccessRequired), findsOneWidget);
      expect(find.text(AppStrings.camera), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('unsent'), findsOneWidget);
      expect(repo.getMessages('attachments'), isEmpty);
      expect(gallery.isClosed, isTrue);
    },
  );

  test('Location validates coordinates and respects blocking', () async {
    final repo = InMemoryChatRepository.empty();
    final cubit = ConversationCubit(
      conversationId: 'attachments',
      repository: repo,
    );
    const place = ChatLocation(
      address: 'Tehran',
      latitude: 35.7,
      longitude: 51.4,
    );
    expect(
      cubit.sendLocation(
        const ChatLocation(address: 'Bad', latitude: 100, longitude: 0),
      ),
      isNull,
    );
    expect(
      cubit.sendLocation(place)!.location!.mapUri.queryParameters['mlat'],
      '35.7',
    );
    cubit.setBlocked(true);
    expect(cubit.sendLocation(place), isNull);
    expect(repo.getMessages('attachments'), hasLength(1));
    await cubit.close();
  });

  test(
    'Camera photo streams through the gallery file representation',
    () async {
      final photo = CameraPhotoFile(XFile('assets/img2.png'));
      expect(photo.name, 'img2.png');
      expect(await photo.length(), File('assets/img2.png').lengthSync());
      final streamed = await photo.readAsByteStream().fold<List<int>>(
        [],
        (all, chunk) => all..addAll(chunk),
      );
      expect(streamed, await photo.readAsBytes());
    },
  );
}
