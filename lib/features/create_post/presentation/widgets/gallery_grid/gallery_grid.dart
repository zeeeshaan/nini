import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_preview/gallery_preview.dart';

class GalleryGrid extends StatelessWidget {
  const GalleryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<GalleryCubit, GalleryState>(
      builder: (context, state) {
        return ColoredBox(
          color: colors.surfaceContainerHighest,
          child: Column(
            children: [
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.copy_all_outlined,
                  size: 23,
                  color: colors.onSurface,
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _GalleryBody(state: state)),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 20,
                      child: Center(
                        child: _GalleryTabSelector(selected: state.tab),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody({required this.state});

  final GalleryState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (state.tab == GalleryTab.file) {
      return _FilesGrid(state: state);
    }

    if (state.status == GalleryStatus.loading) {
      return Center(child: CircularProgressIndicator(color: colors.onSurface));
    }

    if (state.status == GalleryStatus.denied) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppStrings.galleryAccessRequired,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: PhotoManager.openSetting,
              child: const Text(AppStrings.openSettings),
            ),
            TextButton(
              onPressed: () {
                context.read<GalleryCubit>().changeTab(state.tab);
              },
              child: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      );
    }

    if (state.status == GalleryStatus.failure) {
      return _GalleryMessage(
        message: state.errorMessage ?? AppStrings.galleryLoadFailed,
      );
    }

    if (state.assets.isEmpty) {
      return _GalleryMessage(
        message: state.tab == GalleryTab.video
            ? AppStrings.noVideos
            : AppStrings.noPhotos,
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
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: state.assets.length + (state.loadingMore ? 1 : 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          if (index >= state.assets.length) {
            return Center(
              child: CircularProgressIndicator(
                color: colors.onSurface,
                strokeWidth: 2,
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
            ),

            if (asset.type == AssetType.video)
              Positioned(
                left: 5,
                bottom: 5,
                child: Icon(Icons.videocam, size: 19, color: colors.surface),
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
                  child: Icon(Icons.check, size: 16, color: colors.surface),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilesGrid extends StatelessWidget {
  const _FilesGrid({required this.state});

  final GalleryState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final files = state.selected.where((item) => item.file != null).toList();

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: files.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
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
                        Icon(
                          Icons.add_circle_outline,
                          size: 30,
                          color: colors.onSurface,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.addFiles,
                          style: TextStyle(
                            fontSize: 10,
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
                  child: Icon(Icons.close, size: 16, color: colors.onSurface),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GalleryTabSelector extends StatelessWidget {
  const _GalleryTabSelector({required this.selected});

  final GalleryTab selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 246,
      height: 44,
      decoration: BoxDecoration(
        color: colors.onSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _buildTab(context, AppStrings.photo, GalleryTab.photo),
          _buildTab(context, AppStrings.video, GalleryTab.video),
          _buildTab(context, AppStrings.file, GalleryTab.file),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, GalleryTab tab) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: selected == tab
            ? (tab == GalleryTab.file
                  ? () {
                      context.read<GalleryCubit>().pickFiles();
                    }
                  : null)
            : () {
                context.read<GalleryCubit>().changeTab(tab);
              },
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: colors.surface,
              fontSize: 13,
              fontWeight: selected == tab ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
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
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
