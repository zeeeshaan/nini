import 'package:nini/shared/models/post/post_unit.dart';

/// English copy for post quantities and unit labels.
abstract final class PostDetailStrings {
  static const quantity = 'Quantity';
  static const increaseQuantity = 'Increase quantity';

  static String unit(PostUnit unit) => switch (unit) {
    PostUnit.piece || PostUnit.item => 'item',
    PostUnit.hour => 'hour',
    PostUnit.day => 'day',
    PostUnit.session => 'session',
    PostUnit.project => 'project',
    PostUnit.meter => 'meter',
    PostUnit.centimeter => 'centimeter',
    PostUnit.kilogram => 'kilogram',
    PostUnit.set => 'set',
  };

  static String persianDigits(String value) => value;
}
