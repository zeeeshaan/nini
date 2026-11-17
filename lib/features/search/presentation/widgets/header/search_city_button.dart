import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class SearchCityButton extends StatelessWidget {
  const SearchCityButton({
    super.key,
    required this.city,
    required this.onPressed,
  });

  final String city;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: SearchStrings.chooseCity,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(AppIcons.location, size: 25),
              const SizedBox(height: 2),
              Text(
                SearchStrings.display(city),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallPrint,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
