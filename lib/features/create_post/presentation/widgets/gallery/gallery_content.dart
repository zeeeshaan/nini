import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
import 'package:hywork/features/create_post/presentation/cubit/gallery_cubit.dart';

import 'gallery_grid.dart';
import 'gallery_preview.dart';

/// Keep the gallery usable when a landscape window has little vertical space.
class GalleryContent extends StatelessWidget {
  const GalleryContent({super.key, this.previewOnly = false});
  final bool previewOnly;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final preview =
          BlocSelector<GalleryCubit, GalleryState, List<GalleryAttachment>>(
            selector: (state) => state.selected,
            builder: (_, selected) => GalleryPreview(selected: selected),
          );
      if (constraints.maxHeight < 360 && constraints.maxWidth >= 480) {
        return Row(
          children: [
            Expanded(child: preview),
            const VerticalDivider(width: 1),
            Expanded(child: GalleryGrid(previewOnly: previewOnly)),
          ],
        );
      }
      return Column(
        children: [
          Expanded(flex: 6, child: preview),
          SizedBox(height: constraints.maxHeight < 500 ? 8 : 24),
          const Divider(height: 1, thickness: .5),
          Expanded(flex: 5, child: GalleryGrid(previewOnly: previewOnly)),
        ],
      );
    },
  );
}
