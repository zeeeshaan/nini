import 'package:nini/shared/models/post/post_unit.dart';

/// Unit labels for Home/Detail price rows (Figma Persian unit beside price).
abstract final class PostDetailStrings {
  static const quantity = 'Quantity';
  static const increaseQuantity = 'Increase quantity';

  static String unit(PostUnit unit) => switch (unit) {
    PostUnit.piece || PostUnit.item => 'عدد',
    PostUnit.hour => 'ساعت',
    PostUnit.day => 'روز',
    PostUnit.session => 'جلسه',
    PostUnit.project => 'پروژه',
    PostUnit.meter => 'متر',
    PostUnit.centimeter => 'سانتی‌متر',
    PostUnit.kilogram => 'کیلوگرم',
    PostUnit.set => 'ست',
  };

  static String persianDigits(String value) => value;
}
