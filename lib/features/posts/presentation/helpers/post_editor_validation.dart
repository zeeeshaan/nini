import 'package:nini/core/localization/profile_post_strings.dart';

/// Accept the same Persian, Arabic, and Latin digits as the existing form.
abstract final class PostEditorValidation {
  static double? number(String input) {
    var value = input.trim();
    const digits = '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < digits.length; i++) {
      value = value.replaceAll(digits[i], '${i % 10}');
    }
    return double.tryParse(
      value
          .replaceAll(RegExp('[,٬ ]'), '')
          .replaceAll('٫', '.')
          .replaceAll(RegExp('[%٪]'), ''),
    );
  }

  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty
      ? ProfilePostStrings.required
      : null;
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = number(value);
    return parsed == null || !parsed.isFinite || parsed < 0
        ? ProfilePostStrings.invalidNumber
        : null;
  }

  static String? discount(String? value) {
    final error = price(value);
    return error != null || (number(value ?? '') ?? 0) > 100
        ? ProfilePostStrings.invalidDiscount
        : null;
  }

  static String? stock(String? value) {
    final parsed = number(value ?? '');
    return price(value) != null ||
            (parsed != null && parsed != parsed.truncateToDouble())
        ? ProfilePostStrings.invalidStock
        : null;
  }
}
