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
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: state.categories.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final category = index == 0
                        ? null
                        : state.categories[index - 1];
                    return ProfileCategoryChip(
                      label: category == null
                          ? ProfilePostStrings.all
                          : ProfilePostStrings.categoryName(
                              category.id,
                              category.name,
                            ),
                      isSelected: state.selectedId == category?.id,
                      onTap: () {
                        context.read<ProfileCategoriesCubit>().select(
                          category?.id,
                        );
                        onCategoryChanged?.call(category?.id ?? '');
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: ProfilePostStrings.manageTabs,
                onPressed:
                    onAddPressed ??
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileCategoriesScreen(),
                      ),
                    ),
                icon: const Icon(Icons.add, size: 30),
              ),
            ],
          ),
        ),
      );
}
