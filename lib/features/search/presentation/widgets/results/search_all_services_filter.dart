import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';

/// Clears the query while retaining the current city selection.
class SearchAllServicesFilter extends StatelessWidget {
  const SearchAllServicesFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ChoiceChip(
        label: const Text(SearchStrings.allServices),
        labelStyle: AppTextStyles.labelMedium,
        selected: selected,
        showCheckmark: false,
        selectedColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        onSelected: (_) => onSelected(),
      ),
    ),
  );
}
