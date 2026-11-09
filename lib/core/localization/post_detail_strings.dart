import 'package:nini/shared/models/post/post_unit.dart';

/// Persian copy for post quantities and unit labels.
abstract final class PostDetailStrings {
  static const quantity = 'تعداد';
  static const increaseQuantity = 'افزایش تعداد';

  static String unit(PostUnit unit) => switch (unit) {
    PostUnit.piece || PostUnit.item => 'عدد',
    PostUnit.hour => 'ساعت',
    PostUnit.day => 'روز',
    PostUnit.session => 'جلسه',
    PostUnit.project => 'پروژه',
    PostUnit.meter => 'متر',
    PostUnit.centimeter => 'سانتی‌متر',
    PostUnit.kilogram => 'کیلوگرم',
    PostUnit.set => 'مجموعه',
  };

  static String persianDigits(String value) => value
      .replaceAllMapped(
        RegExp('[0-9]'),
        (match) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(match[0]!)],
      )
      .replaceAll('.', '٫');
}
