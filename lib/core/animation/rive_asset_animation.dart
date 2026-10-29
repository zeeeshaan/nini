import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Reusable player for bundled .riv artwork, with a quiet loading/error fallback.
/// Add the artwork to pubspec.yaml, then provide its asset path here.
class RiveAssetAnimation extends StatefulWidget {
  const RiveAssetAnimation({
    super.key,
    required this.asset,
    this.fallback = const SizedBox.shrink(),
  });

  final String asset;
  final Widget fallback;

  @override
  State<RiveAssetAnimation> createState() => _RiveAssetAnimationState();
}

class _RiveAssetAnimationState extends State<RiveAssetAnimation> {
  late rive.FileLoader _loader;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _loader = rive.FileLoader.fromAsset(
      widget.asset,
      riveFactory: rive.Factory.rive,
    );
  }

  @override
  void didUpdateWidget(covariant RiveAssetAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _loader.dispose();
      _load();
    }
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.fallback;
    }

    return rive.RiveWidgetBuilder(
      key: ValueKey(widget.asset),
      fileLoader: _loader,
      builder: (context, state) => switch (state) {
        rive.RiveLoaded() => rive.RiveWidget(
          controller: state.controller,
          fit: rive.Fit.contain,
        ),
        _ => widget.fallback,
      },
    );
  }
}
