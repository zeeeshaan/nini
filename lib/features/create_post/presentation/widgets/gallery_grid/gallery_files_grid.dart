import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/create_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_preview/gallery_preview.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class GalleryFilesGrid extends StatelessWidget {
  const GalleryFilesGrid({super.key, required this.state});

  final GalleryState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final files = state.selected.where((item) => item.file != null).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              CreatePostStrings.errorMessage(
                state.errorMessage ?? CreatePostStrings.filesPickerHelp,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppTextStyles.helper,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 90),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:
                  120 * (MediaQuery.textScalerOf(context).scale(10) / 10),
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              mainAxisExtent: 90 + MediaQuery.textScalerOf(context).scale(10),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              // First tile: add more documents.
              if (index == 0) {
                return Material(
                  color: colors.surfaceContainerHighest,
                  child: InkWell(
                    onTap: state.isPickingFiles
                        ? null
                        : () {
                            context.read<GalleryCubit>().pickFiles();
                          },
                    child: state.isPickingFiles
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(
                                AppIcons.addCircle,
                                size: 30,
                                color: colors.onSurface,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CreatePostStrings.addFiles,
                                style: AppTextStyles.smallPrint.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              }

              final attachment = files[index - 1];

              return Material(
                color: colors.surface,
                child: InkWell(
                  onTap: () {
                    context.read<GalleryCubit>().removeAttachment(attachment);
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GalleryFileTile(
                          file: attachment.file!,
                          showName: true,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: AppIcon(
                          AppIcons.close,
                          size: 16,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: files.length + 1),
          ),
        ),
      ],
    );
  }
}
