import 'package:nini/core/localization/strings/category_strings.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';

import '../../cubit/profile_categories_cubit.dart';
import 'category_sheet_actions.dart';

Future<void> showCategoryDelete(
  BuildContext context,
  ProfileCategory category,
) {
  final categories = context.read<ProfileCategoriesCubit>()..clearError();
  return showPostDialog<void>(
    context,
    BlocProvider.value(
      value: categories,
      child: CategoryStrings.of(context).english
          ? _CategoryDeleteSheet(category: category)
          : PersianFeature(child: _CategoryDeleteSheet(category: category)),
    ),
  );
}

class _CategoryDeleteSheet extends StatelessWidget {
  const _CategoryDeleteSheet({required this.category});
  final ProfileCategory category;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
        builder: (context, state) => PopScope(
          canPop: !state.saving,
          child: PostDialog(
            title: CategoryStrings.of(context)
                .text(ProfilePostStrings.deleteTab),
            textDirection: TextDirection.ltr,
            actions: CategorySheetActions(
              saving: state.saving,
              destructive: true,
              submitLabel: CategoryStrings.of(context)
                  .text(ProfilePostStrings.delete),
              onSubmit: () async {
                final deleted = await context
                    .read<ProfileCategoriesCubit>()
                    .delete(category.id);
                if (context.mounted && deleted) Navigator.pop(context);
              },
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  CategoryStrings.of(context).deleteQuestion(
                    CategoryStrings.of(context)
                        .name(category.id, category.name),
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 12),
                Text(
                  CategoryStrings.of(context)
                      .text(ProfilePostStrings.deleteHelp),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      CategoryStrings.of(context).text(state.error!),
                      style: AppTextStyles.inherit.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
}
