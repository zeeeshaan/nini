import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/posts/presentation/pages/profile_categories_screen.dart';

import 'profile_category_chip.dart';

class ProfileCategoryChips extends StatelessWidget {
  const ProfileCategoryChips({
    super.key,
    this.onCategoryChanged,
    this.onAddPressed,
  }) : _publicCategories = null;

  const ProfileCategoryChips.readOnly({
    super.key,
    required ProfileCategoryList categories,
  }) : _publicCategories = categories,
       onCategoryChanged = null,
       onAddPressed = null;

  final ProfileCategoryList? _publicCategories;
  final ValueChanged<String>? onCategoryChanged;
  final VoidCallback? onAddPressed;
  @override
  Widget build(BuildContext context) {
    final publicCategories = _publicCategories;
    if (publicCategories != null) {
      return _chips(context, publicCategories.items, publicCategories.allCount);
    }
    return BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
      builder: (context, state) => _chips(
        context,
        state.categories,
        state.allCount,
        selectedId: state.selectedId,
        onSelect: (id) {
          context.read<ProfileCategoriesCubit>().select(id);
          onCategoryChanged?.call(id ?? '');
        },
      ),
    );
  }

  Widget _chips(
    BuildContext context,
    List<ProfileCategory> categories,
    int? allCount, {
    String? selectedId,
    ValueChanged<String?>? onSelect,
  }) {
    final readOnly = _publicCategories != null;
    final offset = readOnly ? 1 : 2;
    return SizedBox(
      height:
          44 +
          (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
                0,
                double.infinity,
              ) *
              1.4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: categories.length + offset,
        separatorBuilder: (_, index) =>
            SizedBox(width: !readOnly && index == 0 ? 12 : 6),
        itemBuilder: (context, index) {
          if (!readOnly && index == 0) {
            return IconButton(
              tooltip: ProfilePostStrings.manageTabs,
              padding: EdgeInsets.zero,
              onPressed:
                  onAddPressed ??
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileCategoriesScreen(),
                    ),
                  ),
              icon: const Icon(Icons.add, size: 30),
            );
          }
          final category = index == offset - 1
              ? null
              : categories[index - offset];
          return ProfileCategoryChip(
            count: category == null ? allCount : category.postsCount,
            label: category == null
                ? ProfilePostStrings.all
                : ProfilePostStrings.categoryName(category.id, category.name),
            isSelected: selectedId == category?.id,
            onTap: onSelect == null ? null : () => onSelect(category?.id),
          );
        },
      ),
    );
  }
}
