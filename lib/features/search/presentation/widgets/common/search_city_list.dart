import 'package:flutter/material.dart';

import 'package:nini/core/localization/strings/search_strings.dart';

/// The reference design's full-width city picker, inside the Search screen.
class SearchCityList extends StatelessWidget {
  const SearchCityList({
    super.key,
    required this.selectedCity,
    required this.onSelected,
  });

  final String selectedCity;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return ListView.builder(
      key: const PageStorageKey('search_cities'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: SearchStrings.cities.length,
      itemBuilder: (context, index) {
        final city = SearchStrings.cities[index];
        final selected = city == selectedCity;
        return Semantics(
          checked: selected,
          inMutuallyExclusiveGroup: true,
          child: InkWell(
            onTap: () => onSelected(city),
            child: SizedBox(
              height: 36,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: foreground, width: 1.7),
                    ),
                    child: selected
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: foreground,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    SearchStrings.display(city),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
