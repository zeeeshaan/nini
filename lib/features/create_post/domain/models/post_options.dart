import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/models/post/post_attributes.dart';

export 'package:nini/shared/models/post/post_attributes.dart';

enum PreparationTime {
  none('آماده‌سازی ندارد', null),
  sameDay('همان روز', 0),
  oneDay('۱ روز', 1),
  twoDays('۲ روز', 2),
  threeDays('۳ روز', 3),
  fiveDays('۵ روز', 5),
  sevenDays('۷ روز', 7),
  tenDays('۱۰ روز', 10),
  fourteenDays('۱۴ روز', 14),
  thirtyDays('۳۰ روز', 30);

  const PreparationTime(this.label, this.days);
  final String label;
  final int? days;
}

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
}

enum InventoryStatus {
  inStock(AppStrings.stockAvailable),
  outOfStock(AppStrings.stockUnavailable),
  preOrder(AppStrings.preOrder);

  const InventoryStatus(this.label);
  final String label;
}

class AddressSelection {
  const AddressSelection({required this.selected, required this.saved});
  final PostAddress selected;
  final List<PostAddress> saved;
}

/// A null result clears a saved schedule; dismissing the sheet returns no result.
class ScheduleSelection {
  const ScheduleSelection(this.schedule);
  final PostSchedule? schedule;
}
