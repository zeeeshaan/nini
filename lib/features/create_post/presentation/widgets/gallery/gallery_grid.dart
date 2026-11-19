import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/data/gallery_library_changes.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'gallery_access_notice.dart';
import 'gallery_body.dart';
import 'gallery_tab_selector.dart';

class GalleryGrid extends StatefulWidget {
  const GalleryGrid({
    super.key,
    this.compact = false,
    this.previewOnly = false,
  });

  /// The chat sheet reuses the same assets/selection without the post toolbar.
  final bool compact;
  final bool previewOnly;

  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> with WidgetsBindingObserver {
  VoidCallback? _stopListening;
  @override
  void initState() {
    super.initState();
    if (!widget.previewOnly) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.previewOnly) {
      _syncLibraryObserver(context.read<GalleryCubit>().state);
    }
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
    if (!widget.previewOnly) WidgetsBinding.instance.removeObserver(this);
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
        return LayoutBuilder(
          builder: (context, constraints) => ColoredBox(
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
                      tooltip: CreatePostStrings.refreshGallery,
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
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .4,
                    ),
                    child: SingleChildScrollView(
                      child: GalleryAccessNotice(
                        busy: state.status == GalleryStatus.loading,
                      ),
                    ),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GalleryBody(
                          state: state,
                          bottomPadding: widget.compact ? 0 : 90,
                        ),
                      ),

                      if (!widget.compact)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 20,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Center(
                              child: GalleryTabSelector(selected: state.tab),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
