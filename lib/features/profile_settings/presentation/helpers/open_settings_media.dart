import 'package:flutter/material.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/shared/models/post/post_media.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';
import 'package:open_filex/open_filex.dart';

import '../../domain/settings_media_item.dart';
import '../widgets/my_media/settings_media_preview.dart';

Future<void> openSettingsMedia(
  BuildContext context,
  SettingsMediaItem item,
) async {
  if (item.media.type == PostMediaType.image ||
      item.media.source == PostMediaSource.asset) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsMediaPreview(media: item.media),
      ),
    );
    return;
  }
  try {
    final result = await OpenFilex.open(item.media.path);
    if (result.type != ResultType.done && context.mounted) {
      AppToast.error(context, AppStrings.fileOpenFailed);
    }
  } catch (_) {
    if (context.mounted) {
      AppToast.error(context, AppStrings.fileOpenFailed);
    }
  }
}
