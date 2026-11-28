import 'package:flutter/material.dart';

import 'package:hywork/features/create_post/models/gallery_attachment.dart';
import 'package:hywork/features/create_post/screens/create_post_gallery_screen.dart';
import 'package:hywork/features/create_post/widgets/post_form_option_tile/post_form_option_tile.dart';
import 'package:hywork/features/create_post/widgets/selected_media_grid/selected_media_grid.dart';

import 'file_list.dart';

class TeamAttachmentsSection extends StatelessWidget {
  const TeamAttachmentsSection({
    super.key,
    required this.attachments,
    required this.onAddAttachments,
    required this.onRemoveAttachment,
    required this.horizontalPadding,
    required this.spacing,
  });

  final List<GalleryAttachment> attachments;
  final ValueChanged<List<GalleryAttachment>> onAddAttachments;
  final ValueChanged<String> onRemoveAttachment;

  final double horizontalPadding;
  final double spacing;

  Future<void> _openGallery(BuildContext context) async {
    final selected = await Navigator.of(context).push<List<GalleryAttachment>>(
      MaterialPageRoute(
        builder: (galleryContext) {
          return CreatePostGalleryScreen(
            nextLabel: 'Add',
            onNext: (attachments) {
              Navigator.of(galleryContext).pop(attachments);
            },
          );
        },
      ),
    );

    if (!context.mounted || selected == null || selected.isEmpty) {
      return;
    }

    onAddAttachments(selected);
  }

  @override
  Widget build(BuildContext context) {
    final media = attachments
        .where((attachment) => !attachment.isFile)
        .toList();

    final files = attachments.where((attachment) => attachment.isFile).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: PostFormOptionTile(
            label: 'Upload File & Picture',
            trailing: const Icon(Icons.cloud_upload_outlined),
            onTap: () => _openGallery(context),
          ),
        ),

        SizedBox(height: spacing),

        // Existing image/video preview grid.
        SelectedMediaGrid(attachments: media),

        if (files.isNotEmpty) ...[
          SizedBox(height: spacing),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: TeamFileList(files: files, onRemove: onRemoveAttachment),
          ),
        ],
      ],
    );
  }
}
