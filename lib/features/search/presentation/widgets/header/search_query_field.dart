import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class SearchQueryField extends StatelessWidget {
  const SearchQueryField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showClear,
    required this.onChanged,
    required this.onSearch,
    required this.onTap,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch, onTap, onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: theme.colorScheme.onSurface.withValues(alpha: .65),
        width: .7,
      ),
    );

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
      child: AppTextField(
        controller: controller,
        focusNode: focusNode,
        hint: SearchStrings.hint,
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.search,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: (_) => onSearch(),
        prefixIcon: IconButton(
          tooltip: AppStrings.search,
          onPressed: onSearch,
          icon: const AppIcon(AppIcons.search, size: 19),
        ),
        suffixIcon: showClear
            ? IconButton(
                tooltip: SearchStrings.clearQuery,
                onPressed: onClear,
                icon: const AppIcon(AppIcons.close, size: 16),
              )
            : null,
      ),
    );
  }
}
