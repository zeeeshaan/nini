import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_details_screen.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery/gallery_content.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class CreatePostGalleryScreen extends StatelessWidget {
  const CreatePostGalleryScreen({
    super.key,
    this.onClose,
    this.onNext,
    this.initialTab = GalleryTab.photo,
    this.nextLabel = CreatePostStrings.next,
  });
  final GalleryTab initialTab;
  final String nextLabel;

  final VoidCallback? onClose;

  // Supports selected photos, videos, and files.
  final ValueChanged<List<GalleryAttachment>>? onNext;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GalleryCubit>(
          create: (_) => GalleryCubit()..changeTab(initialTab),
        ),

        // Holds post form data throughout this flow.
        BlocProvider<CreatePostCubit>(create: (_) => CreatePostCubit()),
      ],
      child: _CreatePostGalleryView(
        onClose: onClose,
        onNext: onNext,
        nextLabel: nextLabel,
      ),
    );
  }
}

class _CreatePostGalleryView extends StatelessWidget {
  const _CreatePostGalleryView({
    this.onClose,
    this.onNext,
    this.nextLabel = CreatePostStrings.next,
  });
  final String nextLabel;

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
      AppToast.warning(context, CreatePostStrings.selectItemRequired);
      return;
    }

    final attachments = await context.read<GalleryCubit>().prepareSelection();
    if (!context.mounted || attachments == null) return;

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

    return Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: BlocListener<GalleryCubit, GalleryState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          AppToast.error(
            context,
            CreatePostStrings.errorMessage(state.errorMessage!),
          );
        },
        child: BlocBuilder<GalleryCubit, GalleryState>(
          buildWhen: (previous, current) =>
              previous.isPreparing != current.isPreparing,
          builder: (context, preparation) => PopScope(
            canPop: !preparation.isPreparing,
            child: Scaffold(
              backgroundColor: colors.surface,
              body: SafeArea(
                child: Column(
                  children: [
                    // Close and Next header
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 68),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: CreatePostStrings.close,
                              onPressed: preparation.isPreparing
                                  ? null
                                  : () => _close(context),
                              icon: AppIcon(
                                AppIcons.close,
                                size: 26,
                                color: colors.onSurface,
                              ),
                            ),

                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child:
                                    BlocSelector<
                                      GalleryCubit,
                                      GalleryState,
                                      List<GalleryAttachment>
                                    >(
                                      selector: (state) => state.selected,
                                      builder: (context, selected) {
                                        return TextButton(
                                          onPressed: preparation.isPreparing
                                              ? null
                                              : () {
                                                  _openPostDetails(
                                                    context,
                                                    selected,
                                                  );
                                                },
                                          child: preparation.isPreparing
                                              ? const SizedBox.square(
                                                  dimension: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(
                                                  nextLabel,
                                                  style: AppTextStyles
                                                      .galleryTitle
                                                      .copyWith(
                                                        color: colors.onSurface,
                                                      ),
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  textAlign: TextAlign.right,
                                                ),
                                        );
                                      },
                                    ),
                              ),
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

                    Expanded(
                      child: AbsorbPointer(
                        absorbing: preparation.isPreparing,
                        child: const GalleryContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
