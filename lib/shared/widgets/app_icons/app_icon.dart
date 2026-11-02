import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:nini/core/theme/app_colors.dart';

/// Displays vector icons or legacy PNGs, preserving transparency/proportions.
///
/// Inherits the current icon theme (black in light mode, white in dark mode).
/// [selected] adds a subtle background without changing the foreground color.
/// Buttons should provide their own tooltip/semantic label;
/// use [semanticLabel] for standalone meaningful icons.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.selected = false,
  });

  final String asset;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final dimension = size ?? iconTheme.size ?? 24;
    final foreground =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? foreground.withValues(alpha: 0.14)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: asset.toLowerCase().endsWith('.svg')
          ? SvgPicture.asset(
              asset,
              width: dimension,
              height: dimension,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
              semanticsLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
            )
          : Image.asset(
              asset,
              width: dimension,
              height: dimension,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              color: foreground,
              colorBlendMode: BlendMode.srcIn,
              semanticLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
            ),
    );
  }
}
