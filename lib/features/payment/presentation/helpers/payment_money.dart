String paymentMoney(int hundredths) {
  final fraction = (hundredths % 100)
      .toString()
      .padLeft(2, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  final whole = (hundredths ~/ 100).toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '$whole${fraction.isEmpty ? '' : '.$fraction'}';
}
