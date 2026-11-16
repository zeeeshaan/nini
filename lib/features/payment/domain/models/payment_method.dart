// dart format width=100

enum PaymentMethod {
  melli("بانک ملی ایران"),
  mellat("بانک ملت"),
  saman("بانک سامان");

  const PaymentMethod(this.label);
  final String label;
  String get asset => 'assets/banks/$name.svg';
}
