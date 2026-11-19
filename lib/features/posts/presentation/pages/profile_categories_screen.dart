import 'package:nini/shared/widgets/app_back_button/app_back_button.dart';
import 'package:nini/core/localization/strings/category_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

import '../cubit/profile_categories_cubit.dart';
import '../widgets/categories/category_delete_sheet.dart';
import '../widgets/categories/category_editor_sheet.dart';
import '../widgets/categories/profile_categories_body.dart';

class ProfileCategoriesScreen extends StatelessWidget {
  const ProfileCategoriesScreen({
    super.key,
    this.english = false,
    this.selectedCategoryId,
    this.onCategorySelected,
  });
  final bool english;
  final String? selectedCategoryId;
  final ValueChanged<ProfileCategory>? onCategorySelected;

  Future<void> _reorder(
    BuildContext context,
    int oldIndex,
    int newIndex,
  ) async {
    final cubit = context.read<ProfileCategoriesCubit>();
    if (cubit.state.saving || cubit.state.loading) return;
    final ids = cubit.state.categories.map((category) => category.id).toList();
    ids.insert(newIndex, ids.removeAt(oldIndex));
    final saved = await cubit.reorder(ids);
    if (!context.mounted || cubit.isClosed || saved) return;
    final error = cubit.state.error;
    if (error != null) {
      AppToast.error(context, CategoryStrings.of(context).text(error));
    }
  }

  @override
  Widget build(BuildContext context) => PersianFeature(
    child: Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
        builder: (context, state) {
          final categories = context.read<ProfileCategoriesCubit>();
          final strings = CategoryStrings.of(context);
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  strings.text(ProfilePostStrings.tabs),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: strings.text(ProfilePostStrings.addTab),
                  onPressed: state.loading || state.saving || state.loadFailed
                      ? null
                      : () => showCategoryEditor(context),
                  icon: const Icon(Icons.add_circle_outline),
                ),

                const AppBackButton(),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ProfileCategoriesBody(
                  state: onCategorySelected == null
                      ? state
                      : state.copyWith(
                          selectedId: selectedCategoryId,
                          clearSelection: selectedCategoryId == null,
                        ),
                  onRetry: categories.load,
                  onSelect:
                      onCategorySelected ??
                      (category) => categories.select(category.id),
                  onEdit: (category) =>
                      showCategoryEditor(context, category: category),
                  onDelete: (category) => showCategoryDelete(context, category),
                  onReorder: (oldIndex, newIndex) =>
                      _reorder(context, oldIndex, newIndex),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
