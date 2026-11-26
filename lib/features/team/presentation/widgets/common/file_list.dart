import 'package:hywork/core/localization/strings/team_strings.dart';
import 'package:flutter/material.dart';

import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';

class TeamFileList extends StatelessWidget {
  const TeamFileList({super.key, required this.files, required this.onRemove});

  final List<GalleryAttachment> files;
  final ValueChanged<String> onRemove;

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
                      tooltip: "Remove file",
                      onPressed: () => onRemove(attachment.id),
                      icon: const Icon(Icons.delete_outline),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (attachment.preparedFile ?? attachment.file!).name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.bodyText.copyWith(
                              color: colors.onSurface,
                            ),
                            textDirection: TextDirection.ltr,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            TeamStrings.selectedFileSize(
                              (attachment.preparedFile ?? attachment.file!)
                                  .lengthSync(),
                            ),
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Icon(
                      Icons.picture_as_pdf_outlined,
                      color: attachment.file!.extension?.toLowerCase() == 'pdf'
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
