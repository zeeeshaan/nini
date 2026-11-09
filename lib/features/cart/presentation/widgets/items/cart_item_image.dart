// dart format width=100
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class CartItemImage extends StatelessWidget {
  const CartItemImage({super.key, required this.url, required this.title});
  final String? url;
  final String title;
  ImageProvider _provider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return NetworkImage(path);
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final placeholder = Theme.of(context).brightness == Brightness.light
          ? AppColors.cartThumbnail
          : Theme.of(context).colorScheme.surfaceContainerHighest;
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ColoredBox(
          color: placeholder,
          child: url == null
              ? const SizedBox.expand()
              : Image(
                  image: _provider(url!),
                  fit: BoxFit.contain,
                  semanticLabel: title,
                  errorBuilder: (_, _, _) =>
                      const Center(child: AppIcon(AppIcons.imageUnavailable, size: 24)),
                ),
        ),
      );
    },
  );
}
