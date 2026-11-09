import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/posts/presentation/pages/profile_categories_screen.dart';

import 'profile_category_chip.dart';

class ProfileCategoryChips extends StatelessWidget {
  const ProfileCategoryChips({
    super.key,
    this.onCategoryChanged,
    this.onAddPressed,
  });
  final ValueChanged<String>? onCategoryChanged;
  final VoidCallback? onAddPressed;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
        builder: (context, state) => SizedBox(
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
            itemCount: state.categories.length + 2,
            separatorBuilder: (_, index) =>
                SizedBox(width: index == 0 ? 12 : 6),
            itemBuilder: (context, index) {
              if (index == 0) {
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
              final category = index == 1
                  ? null
                  : state.categories[index - 2];
              return ProfileCategoryChip(
                label: category == null
                    ? ProfilePostStrings.all
                    : ProfilePostStrings.categoryName(
                        category.id,
                        category.name,
                      ),
                isSelected: state.selectedId == category?.id,
                onTap: () {
                  context.read<ProfileCategoriesCubit>().select(category?.id);
                  onCategoryChanged?.call(category?.id ?? '');
                },
              );
            },
          ),
        ),
      );
}
