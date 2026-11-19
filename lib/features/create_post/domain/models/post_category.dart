/// A backend post category, separate from user-managed profile tabs.
class PostCategory {
  const PostCategory({required this.key, required this.label, this.labelFa});

  final String key, label;
  final String? labelFa;

  factory PostCategory.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    final label = json['label'];
    final labelFa = json['labelFa'];
    if (key is! String ||
        key.trim().isEmpty ||
        key != key.trim() ||
        label is! String ||
        label.trim().isEmpty ||
        (labelFa != null && labelFa is! String)) {
      throw const FormatException('Invalid category response.');
    }
    return PostCategory(key: key, label: label, labelFa: labelFa as String?);
  }
}
