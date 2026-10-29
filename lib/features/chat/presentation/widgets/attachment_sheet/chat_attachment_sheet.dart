import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_grid/gallery_grid.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

enum ChatAttachmentAction { document, location, camera, gallery }

class ChatAttachmentSheetResult {
  const ChatAttachmentSheetResult.action(this.action) : photos = const [];
  ChatAttachmentSheetResult.photos(List<GalleryAttachment> selected)
    : action = null,
      photos = List.unmodifiable(selected);
  final ChatAttachmentAction? action;
  final List<GalleryAttachment> photos;
}

Future<ChatAttachmentSheetResult?> showChatAttachmentSheet(
  BuildContext context, {
  GalleryCubit Function()? galleryFactory,
}) {
  return showModalBottomSheet<ChatAttachmentSheetResult>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.antiAlias,
    builder: (_) => BlocProvider(
      create: (_) => (galleryFactory?.call() ?? GalleryCubit())..load(),
      child: const ChatAttachmentSheet(),
    ),
  );
}

class ChatAttachmentSheet extends StatelessWidget {
  const ChatAttachmentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final height =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical -
        MediaQuery.viewInsetsOf(context).bottom;
    void choose(ChatAttachmentAction action) =>
        Navigator.of(context).pop(ChatAttachmentSheetResult.action(action));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: math.min(460, height * .62),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 34,
                height: 2,
                color: colors.onSurface.withValues(alpha: .8),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _AttachmentOption(
                    label: AppStrings.document,
                    icon: AppIcons.document,
                    onTap: () => choose(ChatAttachmentAction.document),
                  ),
                  _AttachmentOption(
                    label: AppStrings.location,
                    icon: AppIcons.location,
                    onTap: () => choose(ChatAttachmentAction.location),
                  ),
                  _AttachmentOption(
                    label: AppStrings.camera,
                    icon: AppIcons.camera,
                    onTap: () => choose(ChatAttachmentAction.camera),
                  ),
                  _AttachmentOption(
                    label: AppStrings.gallery,
                    icon: AppIcons.image,
                    onTap: () => choose(ChatAttachmentAction.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Expanded(child: GalleryGrid(compact: true)),
              BlocBuilder<GalleryCubit, GalleryState>(
                builder: (context, state) {
                  if (state.selected.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: AppButton(
                      label: AppStrings.sendSelectedAttachments(
                        state.selected.length,
                      ),
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(ChatAttachmentSheetResult.photos(state.selected)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label, icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: label,
            button: true,
            child: Material(
              color: colors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox.square(
                  dimension: 54,
                  child: Center(
                    child: AppIcon(icon, size: 27, color: colors.onPrimary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Text(
              label,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
