import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/home/presentation/cubit/category_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class HomeCategoryChips extends StatelessWidget {
  const HomeCategoryChips({
    super.key,
    this.onCategoryChanged,
    this.onAddPressed,
  });

  final ValueChanged<String>? onCategoryChanged;
  final VoidCallback? onAddPressed;

  static const List<String> _categories = [
    AppStrings.all,
    AppStrings.webDevelopment,
    AppStrings.electricalWiring,
    AppStrings.products,
    AppStrings.photography,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCategoryCubit(),
      child: BlocBuilder<HomeCategoryCubit, String>(
        builder: (context, selectedCategory) {
          return SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final category = _categories[index];

                      return _CategoryChip(
                        label: category,
                        isSelected: selectedCategory == category,
                        onTap: () {
                          context.read<HomeCategoryCubit>().selectCategory(
                            category,
                          );

                          onCategoryChanged?.call(category);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                SizedBox(
                  width: 40,
                  height: 44,
                  child: IconButton(
                    onPressed: onAddPressed,
                    tooltip: AppStrings.addCategory,
                    icon: const AppIcon(AppIcons.add, size: 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSelected
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Text(
              label,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              softWrap: false,
              textScaler: MediaQuery.textScalerOf(context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
