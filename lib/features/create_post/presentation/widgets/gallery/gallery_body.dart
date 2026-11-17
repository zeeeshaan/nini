import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/skeleton/app_shimmer.dart';

import 'gallery_files_grid.dart';

class GalleryBody extends StatelessWidget {
  const GalleryBody({super.key, required this.state, this.bottomPadding = 90});

  final GalleryState state;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    if (state.tab == GalleryTab.file) {
      return GalleryFilesGrid(state: state);
    }

    if (state.status == GalleryStatus.loading) {
      return AppShimmer(
        child: GridView.builder(
          padding: EdgeInsets.only(bottom: bottomPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: 12,
          itemBuilder: (_, index) => const AppSkeletonBox(
            width: double.infinity,
            height: double.infinity,
            radius: 0,
          ),
        ),
      );
    }

    if (state.status == GalleryStatus.denied) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: const Text(
                    CreatePostStrings.galleryAccessRequired,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: PhotoManager.openSetting,
                  child: const Text(
                    CreatePostStrings.openSettings,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<GalleryCubit>().changeTab(state.tab);
                  },
                  child: const Text(
                    CreatePostStrings.tryAgain,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.status == GalleryStatus.failure) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    CreatePostStrings.errorMessage(
                      state.errorMessage ?? CreatePostStrings.galleryLoadFailed,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<GalleryCubit>().changeTab(state.tab),
                  child: const Text(
                    CreatePostStrings.tryAgain,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.assets.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: _GalleryMessage(
          message: state.tab == GalleryTab.video
              ? CreatePostStrings.noVideos
              : CreatePostStrings.noPhotos,
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 300) {
          context.read<GalleryCubit>().loadMore();
        }

        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.only(bottom: bottomPadding),
        itemCount:
            state.assets.length +
            (state.loadingMore || state.loadMoreFailed ? 1 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          if (index >= state.assets.length) {
            if (state.loadMoreFailed) {
              return Center(
                child: TextButton(
                  onPressed: () =>
                      context.read<GalleryCubit>().loadMore(retry: true),
                  child: const Text(
                    CreatePostStrings.retry,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              );
            }
            return const AppShimmer(
              child: AppSkeletonBox(
                width: double.infinity,
                height: double.infinity,
                radius: 0,
              ),
            );
          }

          final asset = state.assets[index];

          final isSelected = state.selected.any(
            (item) => item.asset?.id == asset.id,
          );

          return _GalleryTile(
            asset: asset,
            isSelected: isSelected,
            onTap: () {
              context.read<GalleryCubit>().toggleSelection(asset);
            },
          );
        },
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(240),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: AppIcon(
                  AppIcons.imageUnavailable,
                  color: colors.onSurface,
                ),
              ),
            ),

            if (asset.type == AssetType.video)
              Positioned(
                left: 5,
                bottom: 5,
                child: AppIcon(AppIcons.video, size: 19, color: colors.surface),
              ),

            if (isSelected)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.onSurface,
                  ),
                  child: AppIcon(
                    AppIcons.check,
                    size: 16,
                    color: colors.surface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryMessage extends StatelessWidget {
  const _GalleryMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            message,
            textAlign: TextAlign.right,
            style: AppTextStyles.inherit.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
