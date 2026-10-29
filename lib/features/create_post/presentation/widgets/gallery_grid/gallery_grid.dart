import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/data/gallery_library_changes.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_preview/gallery_preview.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_grid/gallery_access_notice.dart';

class GalleryGrid extends StatefulWidget {
  const GalleryGrid({super.key, this.compact = false});

  /// The chat sheet reuses the same assets/selection without the post toolbar.
  final bool compact;

  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> with WidgetsBindingObserver {
  VoidCallback? _stopListening;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLibraryObserver(context.read<GalleryCubit>().state);
  }

  void _syncLibraryObserver(GalleryState state) {
    final canObserve =
        state.tab != GalleryTab.file && state.permission?.hasAccess == true;
    if (!canObserve) {
      _stopListening?.call();
      _stopListening = null;
    } else {
      _stopListening ??= GalleryLibraryChanges.listen(() {
        if (mounted) context.read<GalleryCubit>().refresh();
      });
    }
  }

  @override
  void dispose() {
    _stopListening?.call();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<GalleryCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<GalleryCubit, GalleryState>(
      listener: (_, state) => _syncLibraryObserver(state),
      builder: (context, state) {
        return ColoredBox(
          color: colors.surfaceContainerHighest,
          child: Column(
            children: [
              if (!widget.compact)
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
                  child: IconButton(
                    tooltip: AppStrings.refreshGallery,
                    onPressed: state.status == GalleryStatus.loading
                        ? null
                        : context.read<GalleryCubit>().refresh,
                    icon: AppIcon(
                      AppIcons.refresh,
                      size: 23,
                      color: colors.onSurface,
                    ),
                  ),
                ),

              if (state.limitedAccess)
                GalleryAccessNotice(
                  busy: state.status == GalleryStatus.loading,
                ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _GalleryBody(
                        state: state,
                        bottomPadding: widget.compact ? 0 : 90,
                      ),
                    ),

                    if (!widget.compact)
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
  const _GalleryBody({required this.state, this.bottomPadding = 90});

  final GalleryState state;
  final double bottomPadding;

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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage ?? AppStrings.galleryLoadFailed,
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () =>
                  context.read<GalleryCubit>().changeTab(state.tab),
              child: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
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
                  child: const Text(AppStrings.retry),
                ),
              );
            }
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

class _FilesGrid extends StatelessWidget {
  const _FilesGrid({required this.state});

  final GalleryState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final files = state.selected.where((item) => item.file != null).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            state.errorMessage ?? AppStrings.filesPickerHelp,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Expanded(
          child: GridView.builder(
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
                              AppIcon(
                                AppIcons.addCircle,
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
            },
          ),
        ),
      ],
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
