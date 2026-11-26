import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/location_strings.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class LocationLabelCard extends StatelessWidget {
  const LocationLabelCard({
    super.key,
    required this.controller,
    required this.onAdd,
  });
  final TextEditingController controller;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Column(
      children: [
        TextField(
          controller: controller,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
          style: AppTextStyles.label,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onAdd(),
          decoration: InputDecoration(
            hintText: LocationStrings.label,
            hintTextDirection: TextDirection.ltr,
            hintStyle: AppTextStyles.label.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Divider(height: 1, thickness: .5),
        ),
        Row(
          children: [
            IconButton(
              tooltip: LocationStrings.add,
              onPressed: onAdd,
              icon: const AppIcon(AppIcons.add, size: 18),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const Expanded(
              child: Text(
                LocationStrings.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTextStyles.smallPrint,
                textDirection: TextDirection.ltr,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    ),
  );
}
