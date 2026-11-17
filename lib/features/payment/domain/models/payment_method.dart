// dart format width=100

enum PaymentMethod {
  melli('Bank Melli'),
  mellat('Bank Mellat'),
  saman('Saman Bank');

  const PaymentMethod(this.label);
  final String label;
  String get asset => 'assets/banks/$name.svg';
}
