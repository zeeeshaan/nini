
import 'package:nini/core/localization/app_string/app_string.dart';

enum PostUnit {
  piece(AppStrings.unitPiece),
  item(AppStrings.unitItem),
  hour(AppStrings.unitHour),
  day(AppStrings.unitDay),
  session(AppStrings.unitSession),
  project(AppStrings.unitProject),
  meter(AppStrings.unitMeter),
  centimeter(AppStrings.unitCentimeter),
  kilogram(AppStrings.unitKilogram),
  set(AppStrings.unitSet);

  const PostUnit(this.label);

  final String label;

  static PostUnit? fromName(String? name) {
    final value = name?.trim().toLowerCase();

    if (value == null || value.isEmpty) return null;

    for (final unit in values) {
      if (unit.name.toLowerCase() == value ||
          unit.label.trim().toLowerCase() == value) {
        return unit;
      }
    }

    return null;
  }
}
