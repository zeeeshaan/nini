import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/search_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class SearchSuggestions extends StatelessWidget {
  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('search_suggestions'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return InkWell(
          onTap: () => onSelected(suggestion),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: .8,
                    ),
                  ),
                  child: const Center(
                    child: AppIcon(AppIcons.search, size: 17),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    SearchStrings.display(suggestion),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
