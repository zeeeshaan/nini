import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/posts/presentation/pages/profile_categories_screen.dart';

/// Uses stable category IDs; a deleted or absent category displays as All only.
class PostCategorySelector extends StatelessWidget {
  const PostCategorySelector({super.key});
  @override
  Widget build(BuildContext context) => PersianFeature(
    child: BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
      builder: (context, categories) => BlocBuilder<CreatePostCubit, PostDraft>(
        builder: (context, draft) {
          final selected = categories.find(draft.profileCategoryId);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                    '${selected?.id}:${categories.categories.map((item) => item.name).join()}',
                  ),
                  initialValue: selected?.id ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: ProfilePostStrings.category,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text(
                        ProfilePostStrings.allOnly,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    for (final category in categories.categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          ProfilePostStrings.categoryName(
                            category.id,
                            category.name,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      ),
                  ],
                  onChanged:
                      categories.loading ||
                          categories.saving ||
                          categories.loadFailed
                      ? null
                      : (id) => context
                            .read<CreatePostCubit>()
                            .selectProfileCategory(id == '' ? null : id),
                  alignment: Alignment.centerRight,
                ),
              ),
              if (categories.loading)
                const LinearProgressIndicator(minHeight: 2),
              if (categories.loadFailed)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        ProfilePostStrings.loadFailed,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    TextButton(
                      onPressed: context.read<ProfileCategoriesCubit>().load,
                      child: const Text(
                        ProfilePostStrings.retry,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileCategoriesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text(
                    ProfilePostStrings.manageTabs,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
