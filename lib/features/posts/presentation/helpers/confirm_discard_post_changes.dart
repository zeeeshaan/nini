import 'package:flutter/material.dart';
import 'package:hywork/core/localization/persian_feature/persian_feature.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';

Future<bool> confirmDiscardPostChanges(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => PersianFeature(
        child: AlertDialog(
          title: const Text(
            ProfilePostStrings.unsavedTitle,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
          ),
          content: const Text(
            ProfilePostStrings.unsavedHelp,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                ProfilePostStrings.keepEditing,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                ProfilePostStrings.discard,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    ) ??
    false;
