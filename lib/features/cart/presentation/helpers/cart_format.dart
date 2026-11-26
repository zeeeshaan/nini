// dart format width=100
import 'package:hywork/core/localization/app_string/app_string.dart';

/// Parse Persian, Arabic or Latin numbers without floating point rounding.
int? parseCartAmount(String input) {
  var value = input.trim().replaceAll('٫', '.');
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  for (var digit = 0; digit < 10; digit++) {
    value = value.replaceAll(persian[digit], '$digit').replaceAll(arabic[digit], '$digit');
  }
  if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  return int.parse(parts[0]) * 100 + (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

String cartAmountInput(int hundredths) {
  final fraction = hundredths % 100;
  final suffix = fraction.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '');
  return '${hundredths ~/ 100}${fraction == 0 ? '' : '.$suffix'}';
}

String cartMoney(int hundredths) {
  final parts = cartAmountInput(hundredths).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return AppStrings.persianDigits('$whole${parts.length == 1 ? '' : '.${parts[1]}'}');
}

String cartQuantity(int hundredths) => AppStrings.persianDigits(cartAmountInput(hundredths));
