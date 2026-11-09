import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/search_strings.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(AppIcons.search, size: 32),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: const Text(
              SearchStrings.noResults,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: const Text(
              SearchStrings.tryAnotherQuery,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: SearchStrings.showAll,
            onPressed: onReset,
            variant: AppButtonVariant.text,
            isExpanded: false,
          ),
        ],
      ),
    ),
  );
}
