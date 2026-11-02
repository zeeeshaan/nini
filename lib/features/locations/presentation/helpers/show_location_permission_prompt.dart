import 'package:flutter/material.dart';
import 'package:nini/core/localization/location_strings.dart';
import 'package:nini/core/permissions/location_permission_service.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

import '../widgets/location_permission_dialog/location_permission_dialog.dart';

/// Called once by the Home entry gate, after the dashboard's first frame.
Future<void> showLocationPermissionPrompt(BuildContext context) async {
  final service = LocationPermissionService();
  if (!service.isSupported) return;
  try {
    if (await service.hasAccess() || !context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.black.withValues(alpha: .65),
      builder: (_) => Theme(
        data: AppTheme.light,
        child: LocationPermissionDialog(service: service),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      AppToast.error(context, LocationStrings.permissionUnavailable);
    }
  }
}
