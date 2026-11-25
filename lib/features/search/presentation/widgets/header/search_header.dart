import 'package:flutter/material.dart';

import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'package:nini/features/search/presentation/widgets/header/search_city_button.dart';
import 'package:nini/features/search/presentation/widgets/header/search_query_field.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.city,
    required this.onChanged,
    required this.onSearch,
    required this.onTap,
    required this.onCityPressed,
    required this.onClear,
    required this.showClear,
    required this.showClose,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String city;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch, onTap, onCityPressed, onClear;
  final bool showClear;
  final bool showClose;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 6, 18),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(
            child: SearchQueryField(
              controller: controller,
              focusNode: focusNode,
              showClear: showClear,
              onChanged: onChanged,
              onTap: onTap,
              onSearch: onSearch,
              onClear: onClear,
            ),
          ),
          const SizedBox(width: 7),
          SearchCityButton(city: city, onPressed: onCityPressed),
          if (showClose)
            IconButton(
              tooltip: SearchStrings.closeSearch,
              onPressed: onClose,
              icon: const AppIcon(AppIcons.backRight, size: 20),
            ),
        ],
      ),
    );
  }
}
