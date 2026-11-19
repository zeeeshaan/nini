import 'package:flutter/material.dart';

Color _skeletonColor(BuildContext context, double opacity) {
  final colors = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    colors.onSurface.withValues(alpha: opacity),
    colors.surface,
  );
}

class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  static Widget when({required bool enabled, required Widget child}) =>
      enabled ? AppShimmer(child: child) : child;

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion || !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _skeletonColor(context, .07);
    final highlightColor = _skeletonColor(context, .11);

    if (_reduceMotion) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final position = _controller.value * 4;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-3 + position, 0),
            end: Alignment(-1 + position, 0),
            colors: [baseColor, highlightColor, baseColor],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

// Reusable placeholder for skeleton layouts.
class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
    this.isCircle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _skeletonColor(context, .07),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
