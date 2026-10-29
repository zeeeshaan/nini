import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_details_screen.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_grid/gallery_grid.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery_preview/gallery_preview.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class CreatePostGalleryScreen extends StatelessWidget {
  const CreatePostGalleryScreen({super.key, this.onClose, this.onNext});

  final VoidCallback? onClose;

  // Supports selected photos, videos, and files.
  final ValueChanged<List<GalleryAttachment>>? onNext;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GalleryCubit>(create: (_) => GalleryCubit()..load()),

        // Holds post form data throughout this flow.
        BlocProvider<CreatePostCubit>(create: (_) => CreatePostCubit()),
      ],
      child: _CreatePostGalleryView(onClose: onClose, onNext: onNext),
    );
  }
}

class _CreatePostGalleryView extends StatelessWidget {
  const _CreatePostGalleryView({this.onClose, this.onNext});

  final VoidCallback? onClose;
  final ValueChanged<List<GalleryAttachment>>? onNext;

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }

    Navigator.of(context).maybePop();
  }

  Future<void> _openPostDetails(
    BuildContext context,
    List<GalleryAttachment> selected,
  ) async {
    if (selected.isEmpty) {
      AppToast.warning(context, AppStrings.selectItemRequired);
      return;
    }

    final attachments = List<GalleryAttachment>.unmodifiable(selected);

    // Preserve the existing optional callback.
    if (onNext != null) {
      onNext!(attachments);
      return;
    }

    // Reuse the same draft Cubit on the details route.
    final createPostCubit = context.read<CreatePostCubit>();

    final published = await Navigator.of(context).push<PostItem>(
      MaterialPageRoute<PostItem>(
        builder: (_) => BlocProvider<CreatePostCubit>.value(
          value: createPostCubit,
          child: CreatePostDetailsScreen(attachments: attachments),
        ),
      ),
    );
    if (context.mounted && published != null) {
      Navigator.of(context).pop(published);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocListener<GalleryCubit, GalleryState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        AppToast.error(context, state.errorMessage!);
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Close and Next header
              SizedBox(
                height: 68,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: AppStrings.close,
                        onPressed: () => _close(context),
                        icon: Icon(
                          Icons.close,
                          size: 26,
                          color: colors.onSurface,
                        ),
                      ),

                      const Spacer(),

                      BlocSelector<
                        GalleryCubit,
                        GalleryState,
                        List<GalleryAttachment>
                      >(
                        selector: (state) => state.selected,
                        builder: (context, selected) {
                          return TextButton(
                            onPressed: () {
                              _openPostDetails(context, selected);
                            },
                            child: Text(
                              AppStrings.next,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Divider(
                height: 1,
                thickness: 0.5,
                color: Theme.of(context).dividerColor,
              ),

              // Large preview for one item.
              // Three-column grid for multiple items.
              Expanded(
                flex: 6,
                child:
                    BlocSelector<
                      GalleryCubit,
                      GalleryState,
                      List<GalleryAttachment>
                    >(
                      selector: (state) => state.selected,
                      builder: (context, selected) {
                        return GalleryPreview(selected: selected);
                      },
                    ),
              ),

              const SizedBox(height: 24),

              Divider(
                height: 1,
                thickness: 0.5,
                color: Theme.of(context).dividerColor,
              ),

              // Device gallery and native file picker
              const Expanded(flex: 5, child: GalleryGrid()),
            ],
          ),
        ),
      ),
    );
  }
}
