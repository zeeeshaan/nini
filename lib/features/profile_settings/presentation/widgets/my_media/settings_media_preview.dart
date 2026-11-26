import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/posts/presentation/widgets/media/post_media_view.dart';
import 'package:hywork/shared/models/post/post_media.dart';

import '../common/settings_page.dart';

class SettingsMediaPreview extends StatelessWidget {
  const SettingsMediaPreview({super.key, required this.media});
  final PostMedia media;
  @override
  Widget build(BuildContext context) => SettingsPage(
    title: ProfileSettingsStrings.myMedia,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            media.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextStyles.body,
            textDirection: TextDirection.ltr,
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: PostMediaView(media: media, fit: BoxFit.contain),
          ),
        ),
      ],
    ),
  );
}
