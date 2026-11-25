import 'package:nini/core/localization/strings/category_strings.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/domain/validation/profile_category_validator.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';

import 'category_sheet_actions.dart';

Future<void> showCategoryEditor(
  BuildContext context, {
  ProfileCategory? category,
}) {
  final categories = context.read<ProfileCategoriesCubit>()..clearError();
  return showPostDialog<void>(
    context,
    BlocProvider.value(
      value: categories,
      child: CategoryStrings.of(context).english
          ? _CategoryEditorSheet(category: category)
          : PersianFeature(child: _CategoryEditorSheet(category: category)),
    ),
  );
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({this.category});
  final ProfileCategory? category;
  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.category == null
        ? ''
        : CategoryStrings.of(context)
              .name(widget.category!.id, widget.category!.name),
  );
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final cubit = context.read<ProfileCategoriesCubit>();
    final saved = widget.category == null
        ? await cubit.create(_name.text)
        : await cubit.rename(widget.category!.id, _name.text);
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
        builder: (context, state) => PopScope(
          canPop: !state.saving,
          child: PostDialog(
            title: widget.category == null
                ? CategoryStrings.of(context).text(ProfilePostStrings.addTab)
                : CategoryStrings.of(context).text(ProfilePostStrings.editTab),
            textDirection: TextDirection.ltr,
            actions: CategorySheetActions(
              saving: state.saving,
              onSubmit: _save,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextFormField(
                        controller: _name,
                        autofocus: true,
                        enabled: !state.saving,
                        maxLength: ProfileCategoryValidator.maxLength,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: CategoryStrings.of(context)
                              .text(ProfilePostStrings.tabName),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        validator: (value) {
                          final error = ProfileCategoryValidator.validateName(
                            value ?? '',
                            state.categories,
                            excludingId: widget.category?.id,
                          );
                          return error == null
                              ? null
                              : CategoryStrings.of(context).text(error);
                        },
                        textDirection: TextDirection.ltr,
                      ),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
