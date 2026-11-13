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

  /// Missing or unknown legacy values must not imply a different sale unit.
  static PostUnit? fromName(String? name) {
    for (final unit in values) {
      if (unit.name == name) return unit;
    }
    return null;
  }
}
