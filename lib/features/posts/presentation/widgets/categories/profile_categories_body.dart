import 'package:hywork/core/localization/strings/category_strings.dart';
import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/shared/widgets/skeleton/list_tile_skeleton.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';

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
    required this.onReorder,
  });
  final ProfileCategoriesState state;
  final VoidCallback onRetry;
  final ValueChanged<ProfileCategory> onSelect, onEdit, onDelete;
  final ReorderCallback onReorder;
  @override
  Widget build(BuildContext context) {
    if (state.loading && state.categories.isEmpty) {
      return AppShimmer(
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, index) =>
              const ListTileSkeleton(showAvatar: false, animated: false),
        ),
      );
    }
    if (state.loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CategoryStrings.of(context)
                  .text(state.error ?? ProfilePostStrings.loadFailed),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                CategoryStrings.of(context).text(ProfilePostStrings.retry),
                textDirection: TextDirection.ltr,
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
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
        ),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      buildDefaultDragHandles: false,
      itemCount: state.categories.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final category = state.categories[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(category.id),
          index: index,
          enabled: !state.loading && !state.saving,
          child: ProfileCategoryRow(
            category: category,
            selected: state.selectedId == category.id,
            enabled: !state.saving,
            onSelect: () => onSelect(category),
            onEdit: () => onEdit(category),
            onDelete: () => onDelete(category),
          ),
        );
      },
    );
  }
}
