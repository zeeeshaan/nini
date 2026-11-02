/// A user-managed profile tab. IDs never change when a tab is renamed.
/// "All" is a virtual filter, so it is never stored as a category.
class ProfileCategory {
  const ProfileCategory({required this.id, required this.name});
  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory ProfileCategory.fromJson(Map<String, dynamic> json) =>
      ProfileCategory(id: json['id'] as String, name: json['name'] as String);
}
