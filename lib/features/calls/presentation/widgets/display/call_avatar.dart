import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class CallAvatar extends StatelessWidget {
  const CallAvatar({
    super.key,
    required this.name,
    this.asset,
    this.rings = false,
    this.radius = 55,
  });
  final String name;
  final String? asset;
  final bool rings;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = Center(
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
        style: AppTextStyles.avatarInitial(radius)
            .copyWith(color: colors.onSurface),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      ),
    );
    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceContainerHighest,
      ),
      child: asset == null
          ? fallback
          : Image.asset(
              asset!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
    if (!rings) return avatar;
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.biggest.shortestSide.clamp(0.0, 360.0);
        return Center(
          child: SizedBox.square(
            dimension: diameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final (factor, stroke, alpha) in [
                  (1.0, 1.0, .06),
                  (.80, 3.0, .07),
                  (.60, 4.0, .09),
                  (.40, 6.0, .14),
                ])
                  FractionallySizedBox(
                    widthFactor: factor,
                    heightFactor: factor,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.onSurface.withValues(alpha: alpha),
                          width: stroke,
                        ),
                      ),
                    ),
                  ),
                SizedBox.square(
                  dimension: (diameter * .34).clamp(0.0, radius * 2),
                  child: FittedBox(child: avatar),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
