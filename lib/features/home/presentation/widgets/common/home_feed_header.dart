import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';

class HomeFeedHeader extends StatelessWidget {
  const HomeFeedHeader({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
    child: Row(
      children: [
        const SizedBox(width: 98),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'HYWORK',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeBrand,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 48, height: 48),
      ],
    ),
  );
}
