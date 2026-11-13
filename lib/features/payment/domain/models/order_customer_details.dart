import 'package:nini/core/localization/app_string/app_string.dart';

enum OrderCustomerField {
  name,
  surname,
  mobile,
  city,
  province,
  address,
  postalCode,
}

/// Customer-entered checkout details; retained by the form and payment route.
class OrderCustomerDetails {
  const OrderCustomerDetails({
    required this.name,
    required this.surname,
    required this.mobile,
    required this.city,
    required this.province,
    required this.address,
    required this.postalCode,
  });

  factory OrderCustomerDetails.fromValues(
    Map<OrderCustomerField, String> values,
  ) {
    String value(OrderCustomerField field) => values[field]?.trim() ?? '';
    return OrderCustomerDetails(
      name: value(OrderCustomerField.name),
      surname: value(OrderCustomerField.surname),
      mobile: normalizeMobile(value(OrderCustomerField.mobile)),
      city: value(OrderCustomerField.city),
      province: value(OrderCustomerField.province),
      address: value(OrderCustomerField.address),
      postalCode: AppStrings.persianDigits(
        value(OrderCustomerField.postalCode),
      ),
    );
  }

  final String name, surname, mobile, city, province, address, postalCode;
  String get fullName => '$name $surname';

  Map<String, dynamic> toJson() => {
    'name': name,
    'surname': surname,
    'mobile': mobile,
    'city': city,
    'province': province,
    'address': address,
    'postalCode': postalCode,
  };

  factory OrderCustomerDetails.fromJson(Map<String, dynamic> json) =>
      OrderCustomerDetails(
        name: json['name'] as String,
        surname: json['surname'] as String,
        mobile: json['mobile'] as String,
        city: json['city'] as String,
        province: json['province'] as String,
        address: json['address'] as String,
        postalCode: json['postalCode'] as String,
      );

  static String normalizeMobile(String value) =>
      AppStrings.persianDigits(value).replaceAll(RegExp(r'[\s()-]'), '');
}
