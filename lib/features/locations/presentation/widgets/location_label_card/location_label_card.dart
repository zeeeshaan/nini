import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/location_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

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
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 12),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onAdd(),
          decoration: InputDecoration(
            hintText: LocationStrings.label,
            hintTextDirection: TextDirection.rtl,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
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
                style: TextStyle(fontSize: 10),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    ),
  );
}
