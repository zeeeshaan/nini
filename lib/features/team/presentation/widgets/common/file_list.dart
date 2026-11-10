
import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';

class TeamFileList extends StatelessWidget {
  const TeamFileList({
    super.key,
    required this.files,
    required this.onRemove,
  });

  final List<GalleryAttachment> files;
  final ValueChanged<String> onRemove;

  String _formatFileSize(int? bytes) {
    if (bytes == null) {
      return 'Selected';
    }

    final sizeInKB = bytes / 1024;
    return 'Selected · ${sizeInKB.toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final attachment in files)
          if (attachment.file != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Remove file',
                      onPressed: () => onRemove(attachment.id),
                      icon: const Icon(Icons.delete_outline),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            attachment.file!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.bodyText.copyWith(
                              color: colors.onSurface,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _formatFileSize(
                              attachment.file!.lengthSync(),
                            ),
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Icon(
                      Icons.picture_as_pdf_outlined,
                      color: attachment.file!.extension
                          ?.toLowerCase() ==
                          'pdf'
                          ? AppColors.pdfBadge
                          : colors.onSurfaceVariant,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
