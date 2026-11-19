/// A user-managed profile tab. IDs never change when a tab is renamed.
/// "All" is a virtual filter, so it is never stored as a category.
class ProfileCategory {
  const ProfileCategory({
    required this.id,
    required this.name,
    this.position,
    this.postsCount,
    this.createdAt,
  });
  final String id;
  final String name;
  final int? position, postsCount;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory ProfileCategory.fromJson(Map<String, dynamic> json) =>
      ProfileCategory(id: json['id'] as String, name: json['name'] as String);

  static bool isBackendId(String id) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(id);

  factory ProfileCategory.fromApiJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final created = json['createdAt'];
    final date = created is String ? DateTime.tryParse(created) : null;
    if (id is! String ||
        !isBackendId(id) ||
        name is! String ||
        name.trim().isEmpty ||
        (created != null && date == null)) {
      throw const FormatException('Invalid profile category response.');
    }
    return ProfileCategory(
      id: id,
      name: name,
      position: _count(json['position']),
      postsCount: _count(json['postsCount']),
      createdAt: date,
    );
  }
}

/// Counts describe server posts, independently of the device's local post grid.
class ProfileCategoryList {
  const ProfileCategoryList({
    this.items = const [],
    this.allCount,
    this.uncategorizedCount,
  });
  final List<ProfileCategory> items;
  final int? allCount, uncategorizedCount;

  factory ProfileCategoryList.fromApiJson(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('Invalid profile categories response.');
    }
    final ids = <String>{};
    final categories = <ProfileCategory>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid profile category response.');
      }
      final category = ProfileCategory.fromApiJson(item);
      if (!ids.add(category.id)) {
        throw const FormatException('Duplicate profile category ID.');
      }
      categories.add(category);
    }
    return ProfileCategoryList(
      items: List.unmodifiable(categories),
      allCount: _count(json['allCount']),
      uncategorizedCount: _count(json['uncategorizedCount']),
    );
  }
}

int? _count(Object? value) {
  if (value == null) return null;
  if (value is int && value >= 0) return value;
  throw const FormatException('Invalid profile category count or position.');
}
