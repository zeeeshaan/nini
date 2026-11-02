import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/profile_post_strings.dart';

import '../cubit/profile_categories_cubit.dart';
import '../widgets/category_delete_sheet/category_delete_sheet.dart';
import '../widgets/category_editor_sheet/category_editor_sheet.dart';
import '../widgets/profile_categories_body/profile_categories_body.dart';

class ProfileCategoriesScreen extends StatelessWidget {
  const ProfileCategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) => PersianFeature(
    child: BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
      builder: (context, state) {
        final categories = context.read<ProfileCategoriesCubit>();
        return Scaffold(
          appBar: AppBar(
            title: const Align(
              alignment: Alignment.centerRight,
              child: Text(
                ProfilePostStrings.tabs,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
            actions: [
              IconButton(
                tooltip: ProfilePostStrings.addTab,
                onPressed: state.loading || state.saving || state.loadFailed
                    ? null
                    : () => showCategoryEditor(context),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ProfileCategoriesBody(
                state: state,
                onRetry: categories.load,
                onSelect: (category) => categories.select(category.id),
                onEdit: (category) =>
                    showCategoryEditor(context, category: category),
                onDelete: (category) => showCategoryDelete(context, category),
              ),
            ),
          ),
        );
      },
    ),
  );
}
