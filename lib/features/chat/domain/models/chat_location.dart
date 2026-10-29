class ChatLocation {
  const ChatLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  final String address;
  final double latitude, longitude;
  bool get isValid =>
      address.trim().isNotEmpty &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
  Uri get mapUri => Uri.parse(
    'https://www.openstreetmap.org/'
    '?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude',
  );
}
