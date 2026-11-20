import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/persian_feature/persian_feature.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/presentation/cubit/post_categories_cubit.dart';
import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/presentation/cubit/create_post_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/posts/presentation/pages/profile_categories_screen.dart';

/// Global post keys and personal profile-category UUIDs stay independent.
class PostCategorySelector extends StatelessWidget {
  const PostCategorySelector({
    super.key,
    this.english = false,
    this.backendCategories = false,
    this.hasError = false,
    this.preserveUnlisted = false,
    this.existingGlobal,
    this.existingPersonal,
  });
  final bool english, backendCategories, hasError, preserveUnlisted;
  final Map<String, dynamic>? existingGlobal, existingPersonal;

  Future<void> _openPersonalCategories(BuildContext context) async {
    final categories = context.read<ProfileCategoriesCubit>();
    unawaited(categories.load(refresh: true));
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: categories,
          child: ProfileCategoriesScreen(english: english),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PersianFeature(
    child: Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: backendCategories
          ? BlocConsumer<ProfileCategoriesCubit, ProfileCategoriesState>(
              listenWhen: (previous, current) {
                final id = context
                    .read<CreatePostCubit>()
                    .state
                    .profileCategoryId;
                return !preserveUnlisted &&
                    id != null &&
                    previous.find(id) != null &&
                    !current.loading &&
                    !current.loadFailed &&
                    current.find(id) == null;
              },
              listener: (context, _) =>
                  context.read<CreatePostCubit>().selectProfileCategory(null),
              builder: (context, personal) =>
                  BlocConsumer<PostCategoriesCubit, PostCategoriesState>(
                    listener: (context, state) {
                      if (!preserveUnlisted &&
                          !state.loading &&
                          state.error == null) {
                        final draft = context.read<CreatePostCubit>();
                        if (state.find(draft.state.categoryKey) == null) {
                          draft.selectCategory(null);
                        }
                      }
                    },
                    builder: (context, categories) =>
                        BlocBuilder<CreatePostCubit, PostDraft>(
                          builder: (context, draft) {
                            final global = categories.find(draft.categoryKey);
                            final profile = personal.loadFailed
                                ? null
                                : personal.find(draft.profileCategoryId);
                            final missingGlobal =
                                preserveUnlisted &&
                                global == null &&
                                draft.categoryKey != null &&
                                existingGlobal?['key'] == draft.categoryKey;
                            final missingPersonal =
                                preserveUnlisted &&
                                profile == null &&
                                draft.profileCategoryId != null &&
                                existingPersonal?['id'] ==
                                    draft.profileCategoryId;
                            final globalLabel =
                                existingGlobal?['label'] is String
                                ? existingGlobal!['label'] as String
                                : draft.categoryKey ?? '';
                            final personalLabel =
                                existingPersonal?['name'] is String
                                ? existingPersonal!['name'] as String
                                : draft.profileCategoryId ?? '';
                            final label = [
                              if (global != null)
                                english
                                    ? global.label
                                    : global.labelFa ?? global.label,
                              if (missingGlobal) globalLabel,
                              if (profile != null) profile.name,
                              if (missingPersonal) personalLabel,
                            ].join(' · ');
                            final items = [
                              if (missingGlobal)
                                DropdownMenuItem<String>(
                                  value: 'post:${draft.categoryKey}',
                                  enabled: false,
                                  child: Text(globalLabel),
                                ),
                              if (missingPersonal)
                                DropdownMenuItem<String>(
                                  value: 'profile:${draft.profileCategoryId}',
                                  enabled: false,
                                  child: Text(personalLabel),
                                ),
                              for (final category in categories.categories)
                                _item(
                                  'post:${category.key}',
                                  english
                                      ? category.label
                                      : category.labelFa ?? category.label,
                                ),
                              if (!personal.loadFailed)
                                for (final category in personal.categories)
                                  _item(
                                    'profile:${category.id}',
                                    category.name,
                                  ),
                              if (draft.profileCategoryId != null)
                                _item(
                                  'profile:',
                                  CreatePostStrings.noProfileCategory,
                                ),
                            ];
                            return _field(
                              context,
                              selectedId: profile != null || missingPersonal
                                  ? 'profile:${profile?.id ?? draft.profileCategoryId}'
                                  : global == null && !missingGlobal
                                  ? null
                                  : 'post:${global?.key ?? draft.categoryKey}',
                              selectedLabel: label,
                              items: items,
                              loading: categories.loading || personal.loading,
                              enabled: items.isNotEmpty && !personal.saving,
                              error:
                                  categories.error ??
                                  (personal.loadFailed
                                      ? personal.error
                                      : null) ??
                                  (!categories.loading &&
                                          !personal.loading &&
                                          categories.categories.isEmpty
                                      ? CreatePostStrings.categoriesEmpty
                                      : null),
                              onRetry: () {
                                if (categories.error != null ||
                                    categories.categories.isEmpty) {
                                  unawaited(
                                    context.read<PostCategoriesCubit>().load(
                                      refresh: true,
                                    ),
                                  );
                                }
                                if (personal.loadFailed) {
                                  unawaited(
                                    context.read<ProfileCategoriesCubit>().load(
                                      refresh: true,
                                    ),
                                  );
                                }
                              },
                              onChanged: (value) {
                                final draft = context.read<CreatePostCubit>();
                                if (value == 'profile:') {
                                  draft.selectProfileCategory(null);
                                } else if (value != null &&
                                    value.startsWith('post:')) {
                                  final key = value.substring('post:'.length);
                                  if (context
                                          .read<PostCategoriesCubit>()
                                          .state
                                          .find(key) !=
                                      null) {
                                    draft.selectCategory(key);
                                  }
                                } else if (value != null &&
                                    value.startsWith('profile:')) {
                                  final state = context
                                      .read<ProfileCategoriesCubit>()
                                      .state;
                                  if (!state.loadFailed) {
                                    final id = value.substring(
                                      'profile:'.length,
                                    );
                                    draft.assignProfileCategory(
                                      id,
                                      state.categories,
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                  ),
            )
          : BlocBuilder<ProfileCategoriesCubit, ProfileCategoriesState>(
              builder: (context, categories) =>
                  BlocBuilder<CreatePostCubit, PostDraft>(
                    builder: (context, draft) => _field(
                      context,
                      selectedId: categories.find(draft.profileCategoryId)?.id,
                      items: [
                        _item(
                          '',
                          english ? 'All only' : ProfilePostStrings.allOnly,
                        ),
                        for (final category in categories.categories)
                          _item(
                            category.id,
                            english
                                ? category.name
                                : ProfilePostStrings.categoryName(
                                    category.id,
                                    category.name,
                                  ),
                          ),
                      ],
                      loading: categories.loading,
                      saving: categories.saving,
                      error: categories.loadFailed
                          ? english
                                ? CreatePostStrings.categoriesLoadFailed
                                : ProfilePostStrings.loadFailed
                          : null,
                      onRetry: context.read<ProfileCategoriesCubit>().load,
                      onChanged: context
                          .read<CreatePostCubit>()
                          .selectProfileCategory,
                    ),
                  ),
            ),
    ),
  );

  DropdownMenuItem<String> _item(String id, String label) => DropdownMenuItem(
    value: id,
    child: Text(
      label,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    ),
  );

  Widget _field(
    BuildContext context, {
    required String? selectedId,
    required List<DropdownMenuItem<String>> items,
    required bool loading,
    bool saving = false,
    required String? error,
    required VoidCallback onRetry,
    required ValueChanged<String?> onChanged,
    String? selectedLabel,
    bool? enabled,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Directionality(
        textDirection: TextDirection.rtl,
        child: DropdownButtonFormField<String>(
          key: ValueKey(
            '$selectedId:${items.map((item) => item.value).join()}',
          ),
          initialValue: selectedId ?? (backendCategories ? null : ''),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: english ? 'Type' : ProfilePostStrings.category,
            enabledBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
            focusedBorder: hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
          ),
          hint: backendCategories
              ? const Text(
                  CreatePostStrings.selectCategory,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                )
              : null,
          items: items,
          selectedItemBuilder: selectedLabel == null
              ? null
              : (_) => [
                  for (final _ in items)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        selectedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
          onChanged: !(enabled ?? (!loading && !saving && error == null))
              ? null
              : (id) => onChanged(id == '' ? null : id),
          alignment: Alignment.centerRight,
        ),
      ),
      if (loading) const LinearProgressIndicator(minHeight: 2),
      if (error != null)
        Row(
          children: [
            Expanded(
              child: Text(
                error,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                english ? 'Retry' : ProfilePostStrings.retry,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      if (!backendCategories || preserveUnlisted)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _openPersonalCategories(context),
            icon: const Icon(Icons.tune, size: 18),
            label: Text(
              english ? 'Manage categories' : ProfilePostStrings.manageTabs,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ),
        ),
    ],
  );
}
