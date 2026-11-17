import 'package:flutter/widgets.dart';

import 'profile_post_strings.dart';

/// Category copy shared by Create Post and Profile.
class CategoryStrings {
  const CategoryStrings(this.english);
  factory CategoryStrings.of(BuildContext context) =>
      CategoryStrings(Localizations.localeOf(context).languageCode == 'en');
  final bool english;

  String name(String id, String name) =>
      english ? name : ProfilePostStrings.categoryName(id, name);
  String deleteQuestion(String name) => english
      ? 'Remove the "$name" category?'
      : ProfilePostStrings.deleteQuestion(name);
  String text(String message) => !english
      ? message
      : switch (message) {
          ProfilePostStrings.tabs => 'Categories',
          ProfilePostStrings.addTab => 'Add category',
          ProfilePostStrings.editTab => 'Edit category',
          ProfilePostStrings.deleteTab => 'Delete category',
          ProfilePostStrings.tabName => 'Category name',
          ProfilePostStrings.cancel => 'Cancel',
          ProfilePostStrings.done => 'Done',
          ProfilePostStrings.delete => 'Delete',
          ProfilePostStrings.saving => 'Saving…',
          ProfilePostStrings.retry => 'Retry',
          ProfilePostStrings.noTabs =>
            'No categories yet. Add one to organise your posts.',
          ProfilePostStrings.loadFailed =>
            'Could not load categories. Try again.',
          ProfilePostStrings.saveFailed => 'Could not save changes. Try again.',
          ProfilePostStrings.nameRequired => 'Enter a category name.',
          ProfilePostStrings.nameTooLong =>
            'Category names must be at most 50 characters.',
          ProfilePostStrings.duplicateName =>
            'A category with this name already exists.',
          ProfilePostStrings.reservedName =>
            'All is a permanent section. Choose another name.',
          ProfilePostStrings.deleteHelp =>
            'Posts in this category will remain visible under All.',
          _ => message,
        };
}
