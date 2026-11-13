import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/chat/data/device_chat_camera.dart';
import 'package:nini/features/chat/domain/models/chat_location.dart';
import 'package:nini/features/chat/presentation/widgets/media/chat_attachment_sheet.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_gallery_screen.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/address_dialog.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class ChatAttachmentSelection {
  ChatAttachmentSelection.photos(List<GalleryAttachment> photos)
    : photos = List.unmodifiable(photos),
      location = null;
  const ChatAttachmentSelection.location(this.location) : photos = const [];
  final List<GalleryAttachment> photos;
  final ChatLocation? location;
}

Future<List<GalleryAttachment>?> pickChatGallery(
  BuildContext context,
  GalleryTab tab,
) => Navigator.of(context).push<List<GalleryAttachment>>(
  MaterialPageRoute(
    builder: (pickerContext) => CreatePostGalleryScreen(
      initialTab: tab,
      nextLabel: AppStrings.sendMessage,
      onNext: (selected) => Navigator.of(pickerContext).pop(selected),
    ),
  ),
);

/// Routes picker UI and returns values; the conversation owns all send guards.
Future<ChatAttachmentSelection?> pickChatAttachment(
  BuildContext context, {
  GalleryCubit Function()? galleryFactory,
  Future<GalleryAttachment?> Function()? capturePhoto,
}) async {
  try {
    final result = await showChatAttachmentSheet(
      context,
      galleryFactory: galleryFactory,
    );
    if (!context.mounted || result == null) return null;
    if (result.photos.isNotEmpty) {
      return ChatAttachmentSelection.photos(result.photos);
    }
    switch (result.action) {
      case ChatAttachmentAction.document:
      case ChatAttachmentAction.gallery:
        final photos = await pickChatGallery(
          context,
          result.action == ChatAttachmentAction.document
              ? GalleryTab.file
              : GalleryTab.photo,
        );
        return photos == null ? null : ChatAttachmentSelection.photos(photos);
      case ChatAttachmentAction.camera:
        final photo = await (capturePhoto ?? DeviceChatCamera().takePhoto)();
        return photo == null ? null : ChatAttachmentSelection.photos([photo]);
      case ChatAttachmentAction.location:
        final selection = await showPostDialog<AddressSelection>(
          context,
          const AddressDialog(doneLabel: AppStrings.sendLocation),
        );
        if (selection == null) return null;
        final address = selection.selected;
        if (!address.hasCoordinates) return null;
        return ChatAttachmentSelection.location(
          ChatLocation(
            address: address.address,
            latitude: address.latitude!,
            longitude: address.longitude!,
          ),
        );
      case null:
        return null;
    }
  } on PlatformException catch (error) {
    if (context.mounted) {
      AppToast.error(
        context,
        error.code.toLowerCase().contains('access')
            ? AppStrings.cameraAccessDenied
            : AppStrings.cameraCaptureFailed,
      );
    }
  } catch (_) {
    if (context.mounted) AppToast.error(context, AppStrings.mediaSendFailed);
  }
  return null;
}
