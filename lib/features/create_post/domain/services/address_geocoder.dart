/// Converts a user-selected map point to editable address text.
abstract interface class AddressGeocoder {
  Future<String?> addressFromCoordinates(
    double latitude,
    double longitude, {
    required String languageCode,
  });
}
