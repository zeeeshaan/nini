import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';

class GalleryAccessNotice extends StatelessWidget {
  const GalleryAccessNotice({super.key, required this.busy});
  final bool busy;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: const Text(
              CreatePostStrings.limitedGalleryAccess,
              textAlign: TextAlign.right,
              style: AppTextStyles.helper,
              textDirection: TextDirection.ltr,
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : context.read<GalleryCubit>().manageAccess,
                child: const Text(
                  CreatePostStrings.selectMoreMedia,
                  style: AppTextStyles.helper,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
              TextButton(
                onPressed: PhotoManager.openSetting,
                child: const Text(
                  CreatePostStrings.fullGalleryAccess,
                  style: AppTextStyles.helper,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
