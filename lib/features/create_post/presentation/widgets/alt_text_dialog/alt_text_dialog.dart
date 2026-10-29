import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_preview/gallery_preview.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class AltTextDialog extends StatefulWidget {
  const AltTextDialog({
    super.key,
    required this.attachments,
    required this.initial,
  });
  final List<GalleryAttachment> attachments;
  final Map<String, String> initial;
  @override
  State<AltTextDialog> createState() => _AltTextDialogState();
}

class _AltTextDialogState extends State<AltTextDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final item in widget.attachments)
      item.id: TextEditingController(text: widget.initial[item.id] ?? ''),
  };
  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PostDialog(
    title: AppStrings.altText,
    icon: AppIcons.target,
    actions: PostDialogActions(
      onDone: () => Navigator.of(context).pop({
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
      }),
    ),
    child: SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            AppStrings.altTextHelp,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (widget.attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(AppStrings.noAttachments),
            ),
          for (final item in widget.attachments)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _controllers[item.id],
                      hint: AppStrings.describeAttachment,
                      maxLines: 3,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox.square(
                    dimension: 82,
                    child: item.asset != null
                        ? AssetEntityImage(
                            item.asset!,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize.square(180),
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>
                                const AppIcon(AppIcons.imageUnavailable),
                          )
                        : GalleryFileTile(file: item.file!),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
