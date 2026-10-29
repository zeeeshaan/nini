import 'package:flutter/material.dart';

import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class CallActionButton extends StatelessWidget {
  const CallActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.foreground,
    this.selected = false,
    this.size = 44,
    this.rotation = 0,
  });
  final String label;
  final String icon;
  final VoidCallback? onPressed;
  final Color? color, foreground;
  final bool selected;
  final double size, rotation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      toggled: selected,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: Size.square(size),
          maximumSize: Size.square(size),
          backgroundColor:
              color ??
              (selected
                  ? colors.onSurface
                  : colors.onSurface.withValues(alpha: .12)),
          foregroundColor:
              foreground ?? (selected ? colors.surface : colors.onSurface),
          disabledForegroundColor: colors.onSurface.withValues(alpha: .4),
          padding: EdgeInsets.zero,
        ),
        icon: Transform.rotate(
          angle: rotation,
          child: AppIcon(icon, size: size >= 50 ? 25 : 21),
        ),
      ),
    );
  }
}
