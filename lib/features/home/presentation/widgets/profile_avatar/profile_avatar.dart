import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';

class HomeProfileAvatar extends StatelessWidget {
  const HomeProfileAvatar({super.key, required this.size});

  final double size;

  static const String _avatarAsset = 'assets/Mask group.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        _avatarAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: AppStrings.profileImage,
      ),
    );
  }
}
