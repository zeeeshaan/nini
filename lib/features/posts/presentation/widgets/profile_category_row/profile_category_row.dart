import 'package:flutter/material.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';

class ProfileCategoryRow extends StatelessWidget {
  const ProfileCategoryRow({
    super.key,
    required this.category,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });
  final ProfileCategory category;
  final bool selected, enabled;
  final VoidCallback onSelect, onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        IconButton(
          tooltip: ProfilePostStrings.deleteTab,
          color: Theme.of(context).colorScheme.error,
          onPressed: enabled ? onDelete : null,
          icon: const Icon(Icons.delete_outline),
        ),
        IconButton(
          tooltip: ProfilePostStrings.editTab,
          onPressed: enabled ? onEdit : null,
          icon: const Icon(Icons.edit_outlined),
        ),
        Expanded(
          child: InkWell(
            onTap: enabled ? onSelect : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Text(
                ProfilePostStrings.categoryName(category.id, category.name),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: ProfilePostStrings.categoryName(category.id, category.name),
          isSelected: selected,
          onPressed: enabled ? onSelect : null,
          icon: Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 19,
          ),
        ),
      ],
    ),
  );
}
