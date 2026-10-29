import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

Future<T?> showPostDialog<T>(BuildContext context, Widget dialog) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: dialog,
    ),
  );
}

/// Shared layout for the reference sheets: handle, right-aligned heading,
/// bounded scrollable content, and optional Cancel/Done actions.
class PostDialog extends StatelessWidget {
  const PostDialog({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.actions,
  });
  final String title;
  final String? icon;
  final Widget child;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final available =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).top;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: (available * .94).clamp(120, double.infinity),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    title,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  AppIcon(icon!, size: 22),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Flexible(fit: FlexFit.loose, child: child),
            if (actions != null) ...[const SizedBox(height: 24), actions!],
          ],
        ),
      ),
    );
  }
}

class PostDialogActions extends StatelessWidget {
  const PostDialogActions({
    super.key,
    required this.onDone,
    this.doneLabel = AppStrings.done,
  });
  final VoidCallback? onDone;
  final String doneLabel;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AppButton(
          label: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          height: 44,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: AppButton(label: doneLabel, height: 44, onPressed: onDone),
      ),
    ],
  );
}

class PostChoiceTile extends StatelessWidget {
  const PostChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: SizedBox.square(
        dimension: 24,
        child: selected
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .22),
                ),
                child: const Center(child: AppIcon(AppIcons.check, size: 16)),
              )
            : null,
      ),
      title: Text(
        label,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      ),
    ),
  );
}

class PostChoiceDialog<T> extends StatelessWidget {
  const PostChoiceDialog({
    super.key,
    required this.title,
    required this.values,
    required this.label,
    this.selected,
    this.icon,
    this.tall = false,
  });
  final String title;
  final List<T> values;
  final String Function(T) label;
  final T? selected;
  final String? icon;
  final bool tall;
  @override
  Widget build(BuildContext context) => PostDialog(
    title: title,
    icon: icon,
    child: SizedBox(
      height: tall ? MediaQuery.sizeOf(context).height * .7 : null,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final value in values)
            PostChoiceTile(
              label: label(value),
              selected: value == selected,
              onTap: () => Navigator.of(context).pop(value),
            ),
          const SizedBox(height: 42),
        ],
      ),
    ),
  );
}
