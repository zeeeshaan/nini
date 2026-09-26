import 'package:flutter/foundation.dart';

/// The shop's own categories, shown as chips on the profile and offered
/// when picking a post's category. Categories added with the profile's "+"
/// are held in memory only, like [PostStore].
class ShopCategories {
  ShopCategories._();

  static const defaults = [
    'طراحی وب',
    'سیم‌کشی برق',
    'محصولات',
    'عکاسی',
    'لوله‌کشی',
  ];

  static final ValueNotifier<List<String>> all = ValueNotifier(defaults);

  /// Adds [name] unless it is blank or already there; returns the trimmed
  /// name, or null when nothing was added.
  static String? add(String name) {
    final n = name.trim();
    if (n.isEmpty || all.value.contains(n)) return null;
    // Newest first, so the new chip shows next to "all" on the profile.
    all.value = [n, ...all.value];
    return n;
  }
}
