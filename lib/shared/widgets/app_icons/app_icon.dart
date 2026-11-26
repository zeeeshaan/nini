import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';

/// Displays vector icons, legacy PNGs, or cached network icons.
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
    this.networkFallback,
  });

  final String asset;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final bool selected;

  /// Local asset shown while a network [asset] loads / if it fails.
  final String? networkFallback;

  static bool _isNetwork(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  String _fallbackFor(String url) {
    if (networkFallback != null) return networkFallback!;
    if (url == AppIcons.cartNav) return AppIcons.cartNavFallback;
    return AppIcons.cartFallback;
  }

  Widget _tintedAsset(
    String path, {
    required double dimension,
    required Color foreground,
  }) {
    return Image.asset(
      path,
      width: dimension,
      height: dimension,
      fit: BoxFit.contain,
      color: foreground,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final dimension = size ?? iconTheme.size ?? 24;
    final foreground =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (dimension * dpr).round().clamp(24, 512);

    final Widget child;
    if (_isNetwork(asset)) {
      final fallback = _fallbackFor(asset);
      child = CachedNetworkImage(
        imageUrl: asset,
        width: dimension,
        height: dimension,
        fit: BoxFit.contain,
        color: foreground,
        colorBlendMode: BlendMode.srcIn,
        memCacheWidth: cachePx,
        memCacheHeight: cachePx,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => _tintedAsset(
          fallback,
          dimension: dimension,
          foreground: foreground,
        ),
        errorWidget: (_, _, _) => _tintedAsset(
          fallback,
          dimension: dimension,
          foreground: foreground,
        ),
      );
    } else if (asset.toLowerCase().endsWith('.svg')) {
      child = SvgPicture.asset(
        asset,
        width: dimension,
        height: dimension,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
        semanticsLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      );
    } else {
      child = Image.asset(
        asset,
        width: dimension,
        height: dimension,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        color: foreground,
        colorBlendMode: BlendMode.srcIn,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? foreground.withValues(alpha: 0.14)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
