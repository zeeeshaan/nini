class PostFeature {
  const PostFeature({
    required this.name,
    required this.value,
    this.apiValue,
    this.unit,
  });
  final String name;
  final String value;

  /// Explicit backend value, when its type is known; the display value stays text.
  final Object? apiValue;
  final String? unit;
  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    if (apiValue != null) 'apiValue': apiValue,
    if (unit != null) 'unit': unit,
  };
  factory PostFeature.fromJson(Map<String, dynamic> json) => PostFeature(
    name: json['name'] as String,
    value: json['value'] as String,
    apiValue: json['apiValue'],
    unit: json['unit'] as String?,
  );
}

class PostSchedule {
  const PostSchedule({required this.startsAt, required this.endsAt});
  final DateTime startsAt;
  final DateTime endsAt;
  factory PostSchedule.fromJson(Map<String, dynamic> json) => PostSchedule(
    startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
    endsAt: DateTime.parse((json['endsAt'] ?? json['startsAt']) as String)
        .toLocal(),
  );
  Map<String, dynamic> toJson() => {
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
  };
}

class PostAddress {
  const PostAddress({
    required this.address,
    this.latitude,
    this.longitude,
    this.city = '',
    this.province = '',
    this.postalCode = '',
    this.buildingNumber = '',
    this.unitNumber = '',
  });
  final String address, city, province, postalCode, buildingNumber, unitNumber;
  final double? latitude;
  final double? longitude;
  bool get hasCoordinates => latitude != null && longitude != null;
  factory PostAddress.fromJson(Map<String, dynamic> json) => PostAddress(
    address: json['address'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    city: json['city'] as String? ?? '',
    province: json['province'] as String? ?? '',
    postalCode: json['postalCode'] as String? ?? '',
    buildingNumber: json['buildingNumber'] as String? ?? '',
    unitNumber: json['unitNumber'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {
    'address': address,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (city.isNotEmpty) 'city': city,
    if (province.isNotEmpty) 'province': province,
    if (postalCode.isNotEmpty) 'postalCode': postalCode,
    if (buildingNumber.isNotEmpty) 'buildingNumber': buildingNumber,
    if (unitNumber.isNotEmpty) 'unitNumber': unitNumber,
  };
}
