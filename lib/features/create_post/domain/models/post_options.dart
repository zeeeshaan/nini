import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/shared/models/post/post_attributes.dart';

export 'package:hywork/shared/models/post/post_attributes.dart';
export 'package:hywork/shared/models/post/post_unit.dart';

enum PreparationTime {
  none('No preparation time', null),
  sameDay('Same day', 0),
  oneDay('1 days', 1),
  twoDays('2 days', 2),
  threeDays('3 days', 3),
  fiveDays('5 days', 5),
  sevenDays('7 days', 7),
  tenDays('10 days', 10),
  fourteenDays('14 days', 14),
  thirtyDays('30 days', 30);

  const PreparationTime(this.label, this.days);
  final String label;
  final int? days;
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
