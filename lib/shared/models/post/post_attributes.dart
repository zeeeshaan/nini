class PostFeature {
  const PostFeature({required this.name, required this.value});
  final String name;
  final String value;
  Map<String, dynamic> toJson() => {'name': name, 'value': value};
  factory PostFeature.fromJson(Map<String, dynamic> json) =>
      PostFeature(name: json['name'] as String, value: json['value'] as String);
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
    required this.latitude,
    required this.longitude,
  });
  final String address;
  final double latitude;
  final double longitude;
  factory PostAddress.fromJson(Map<String, dynamic> json) => PostAddress(
    address: json['address'] as String,
    latitude: (json['latitude'] as num? ?? 0).toDouble(),
    longitude: (json['longitude'] as num? ?? 0).toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };
}
