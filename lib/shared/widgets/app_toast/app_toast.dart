import 'dart:async';

import 'package:nini/core/theme/app_text_styles.dart';

import 'package:flutter/material.dart';

enum AppToastType { success, error, warning, info }

class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    final colors = Theme.of(context).colorScheme;

    // Remove any previous toast before showing a new one.
    dismiss();

    final IconData icon;

    switch (type) {
      case AppToastType.success:
        icon = Icons.check_circle_outline;

      case AppToastType.error:
        icon = Icons.error_outline;

      case AppToastType.warning:
        icon = Icons.warning_amber_rounded;

      case AppToastType.info:
        icon = Icons.info_outline;
    }

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Material(
                    color: colors.inverseSurface,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: colors.onInverseSurface, size: 22),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              message,
                              style: AppTextStyles.toast.copyWith(
                                color: colors.onInverseSurface,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      if (identical(_currentEntry, entry)) {
        dismiss();
      }
    });
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;

    final entry = _currentEntry;
    _currentEntry = null;

    if (entry != null) {
      entry.remove();
      entry.dispose();
    }
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.info);
  }
}
