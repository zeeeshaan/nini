// dart format width=100
import 'package:nini/core/localization/cart_strings.dart';

enum PaymentMethod {
  melli(CartStrings.melli),
  mellat(CartStrings.mellat),
  saman(CartStrings.saman);

  const PaymentMethod(this.label);
  final String label;
  String get asset => 'assets/banks/$name.svg';
}
