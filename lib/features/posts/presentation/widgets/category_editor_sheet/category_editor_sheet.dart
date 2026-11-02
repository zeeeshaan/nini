import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/post_dialog/post_dialog.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/domain/validation/profile_category_validator.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';

import '../category_sheet_actions/category_sheet_actions.dart';

Future<void> showCategoryEditor(
  BuildContext context, {
  ProfileCategory? category,
}) {
  final categories = context.read<ProfileCategoriesCubit>()..clearError();
  return showPostDialog<void>(
    context,
    BlocProvider.value(
      value: categories,
      child: PersianFeature(child: _CategoryEditorSheet(category: category)),
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
        : ProfilePostStrings.categoryName(
            widget.category!.id,
            widget.category!.name,
          ),
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
                ? ProfilePostStrings.addTab
                : ProfilePostStrings.editTab,
            textDirection: TextDirection.rtl,
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
                      textDirection: TextDirection.rtl,
                      child: TextFormField(
                        controller: _name,
                        autofocus: true,
                        enabled: !state.saving,
                        maxLength: 50,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          labelText: ProfilePostStrings.tabName,
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        validator: (value) =>
                            ProfileCategoryValidator.validateName(
                              value ?? '',
                              state.categories,
                              excludingId: widget.category?.id,
                            ),
                        textDirection: TextDirection.rtl,
                      ),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
