import 'package:hywork/core/localization/strings/profile_post_strings.dart';

import '../models/profile_category.dart';

abstract final class ProfileCategoryValidator {
  static const minLength = 2;
  static const maxLength = 40;
  static const maxCategories = 20;
  static String? validateName(
    String input,
    List<ProfileCategory> categories, {
    String? excludingId,
  }) {
    final name = input.trim();
    if (name.isEmpty) return ProfilePostStrings.nameRequired;
    if (name.runes.length < minLength) return ProfilePostStrings.nameTooShort;
    if (name.runes.length > maxLength) return ProfilePostStrings.nameTooLong;
    if (name.toLowerCase() == 'all' || name == 'همه') {
      return ProfilePostStrings.reservedName;
    }
    if (categories.any(
      (item) =>
          item.id != excludingId &&
          (item.name.toLowerCase() == name.toLowerCase() ||
              ProfilePostStrings.categoryName(
                    item.id,
                    item.name,
                  ).toLowerCase() ==
                  name.toLowerCase()),
    )) {
      return ProfilePostStrings.duplicateName;
    }
    return null;
  }
}
