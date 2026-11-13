import 'package:nini/core/localization/strings/category_strings.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/shared/widgets/skeleton/list_tile_skeleton.dart';

import '../../cubit/profile_categories_cubit.dart';
import 'profile_category_row.dart';

class ProfileCategoriesBody extends StatelessWidget {
  const ProfileCategoriesBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });
  final ProfileCategoriesState state;
  final VoidCallback onRetry;
  final ValueChanged<ProfileCategory> onSelect, onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    if (state.loading && state.categories.isEmpty) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, index) => const ListTileSkeleton(showAvatar: false),
      );
    }
    if (state.loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CategoryStrings.of(context).text(ProfilePostStrings.loadFailed),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                CategoryStrings.of(context).text(ProfilePostStrings.retry),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }
    if (state.categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          CategoryStrings.of(context).text(ProfilePostStrings.noTabs),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        for (final category in state.categories)
          ProfileCategoryRow(
            category: category,
            selected: state.selectedId == category.id,
            enabled: !state.saving,
            onSelect: () => onSelect(category),
            onEdit: () => onEdit(category),
            onDelete: () => onDelete(category),
          ),
      ],
    );
  }
}
