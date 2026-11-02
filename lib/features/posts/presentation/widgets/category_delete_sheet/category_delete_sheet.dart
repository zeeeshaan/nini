import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';

import '../../cubit/profile_categories_cubit.dart';
import '../category_sheet_actions/category_sheet_actions.dart';

Future<void> showCategoryDelete(
  BuildContext context,
  ProfileCategory category,
) {
  final categories = context.read<ProfileCategoriesCubit>()..clearError();
  return showPostDialog<void>(
    context,
    BlocProvider.value(
      value: categories,
      child: PersianFeature(child: _CategoryDeleteSheet(category: category)),
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
            title: ProfilePostStrings.deleteTab,
            textDirection: TextDirection.rtl,
            actions: CategorySheetActions(
              saving: state.saving,
              destructive: true,
              submitLabel: ProfilePostStrings.delete,
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
                  ProfilePostStrings.deleteQuestion(
                    ProfilePostStrings.categoryName(category.id, category.name),
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                const Text(
                  ProfilePostStrings.deleteHelp,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textDirection: TextDirection.rtl,
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
