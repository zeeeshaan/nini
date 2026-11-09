import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/domain/models/chat_location.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class ChatLocationView extends StatelessWidget {
  const ChatLocationView({
    super.key,
    required this.location,
    required this.foreground,
    this.onOpen,
  });
  final ChatLocation location;
  final Color foreground;
  final VoidCallback? onOpen;
  Future<void> _open(BuildContext context) async {
    onOpen?.call();
    try {
      if (await launchUrl(
        location.mapUri,
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      /* Show the same recoverable error as an unavailable viewer. */
    }
    if (context.mounted) AppToast.error(context, AppStrings.locationOpenFailed);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.openLocation,
    button: true,
    child: InkWell(
      onTap: () => _open(context),
      child: SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: AppIcon(AppIcons.location, size: 36, color: foreground),
            ),
            const SizedBox(height: 8),
            Text(
              location.address,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.bodyText.copyWith(color: foreground),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.mapPin(location.latitude, location.longitude),
              textDirection: TextDirection.rtl,
              style: AppTextStyles.smallPrint.copyWith(
                color: foreground.withValues(alpha: .65),
              ),
              textAlign: TextAlign.right,
            ),
            Text(
              AppStrings.openLocation,
              style: AppTextStyles.helper.copyWith(
                color: foreground,
                decoration: TextDecoration.underline,
                decorationColor: foreground,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    ),
  );
}
