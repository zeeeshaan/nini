import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';

class HomeProductDetails extends StatelessWidget {
  const HomeProductDetails({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 23,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.mobile,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 17,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: .3),
            ),
          ),
        ],
      ),
    );
  }
}
