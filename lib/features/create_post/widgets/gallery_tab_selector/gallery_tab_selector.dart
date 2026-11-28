import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/features/create_post/cubit/gallery_cubit.dart';

class GalleryTabSelector extends StatelessWidget {
  const GalleryTabSelector({super.key, required this.selected});

  final GalleryTab selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 246,
      constraints: BoxConstraints(
        minHeight:
            44 +
            (MediaQuery.textScalerOf(context).scale(13) - 13).clamp(
                  0,
                  double.infinity,
                ) *
                1.5,
      ),
      decoration: BoxDecoration(
        color: colors.onSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _buildTab(context, CreatePostStrings.photo, GalleryTab.photo),
          _buildTab(context, CreatePostStrings.video, GalleryTab.video),
          _buildTab(context, CreatePostStrings.file, GalleryTab.file),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, GalleryTab tab) {
    final colors = Theme.of(context).colorScheme;

    final VoidCallback? onTap;
    if (selected != tab) {
      onTap = () {
        context.read<GalleryCubit>().changeTab(tab);
      };
    } else if (tab == GalleryTab.file) {
      onTap = () {
        context.read<GalleryCubit>().pickFiles();
      };
    } else {
      onTap = null;
    }

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.compactBody.copyWith(
              color: colors.surface,
              fontWeight: selected == tab
                  ? AppTextStyles.semiBold
                  : AppTextStyles.regular,
            ),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
