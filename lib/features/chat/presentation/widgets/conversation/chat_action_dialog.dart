import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

Future<bool> confirmChatAction(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        content: Text(
          description,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: AppStrings.cancel,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ??
    false;
