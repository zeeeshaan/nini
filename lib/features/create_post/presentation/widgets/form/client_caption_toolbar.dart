import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

/// Client artwork with Quill's existing selection, formatting, undo and redo
/// callbacks. The document/Delta and the other toolbar controls are unchanged.
QuillSimpleToolbarButtonOptions clientCaptionButtons(BuildContext context) {
  final labels = FlutterQuillLocalizations.of(context)!;
  QuillToolbarToggleStyleButtonOptions toggle(String asset, String tooltip) =>
      QuillToolbarToggleStyleButtonOptions(
        // Quill resolves builders through a raw generic; accept dynamic at
        // that boundary, then restore the concrete option type immediately.
        childBuilder: (dynamic _, dynamic value) {
          final extra = value as QuillToolbarToggleStyleButtonExtraOptions;
          return _CaptionIconButton(
            asset: asset,
            tooltip: tooltip,
            selected: extra.isToggled,
            onPressed: extra.onPressed,
          );
        },
      );
  return QuillSimpleToolbarButtonOptions(
    bold: toggle(AppIcons.bold, labels.bold),
    italic: toggle(AppIcons.italic, labels.italic),
    underLine: toggle(AppIcons.underline, labels.underline),
    strikeThrough: toggle(AppIcons.strikethrough, labels.strikeThrough),
    undoHistory: QuillToolbarHistoryButtonOptions(
      tooltip: CreatePostStrings.undo,
      childBuilder: (dynamic _, dynamic value) {
        final extra = value as QuillToolbarHistoryButtonExtraOptions;
        return _CaptionIconButton(
          asset: AppIcons.undo,
          tooltip: CreatePostStrings.undo,
          onPressed: extra.canPressed ? extra.onPressed : null,
        );
      },
    ),
    redoHistory: QuillToolbarHistoryButtonOptions(
      tooltip: CreatePostStrings.redo,
      childBuilder: (dynamic _, dynamic value) {
        final extra = value as QuillToolbarHistoryButtonExtraOptions;
        return _CaptionIconButton(
          asset: AppIcons.redo,
          tooltip: CreatePostStrings.redo,
          onPressed: extra.canPressed ? extra.onPressed : null,
        );
      },
    ),
    base: QuillToolbarBaseButtonOptions(
      iconTheme: QuillIconTheme(
        iconButtonSelectedData: IconButtonData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.primary,
            ),
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.onPrimary,
            ),
            iconColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        iconButtonUnselectedData: IconButtonData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.onSurface,
            ),
            iconColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}

class _CaptionIconButton extends StatelessWidget {
  const _CaptionIconButton({
    required this.asset,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });
  final String asset, tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: selected ? colors.primary : AppColors.transparent,
        foregroundColor: selected ? colors.onPrimary : colors.onSurface,
        disabledForegroundColor: colors.onSurface.withValues(alpha: .4),
      ),
      icon: AppIcon(asset, size: 20),
    );
  }
}
