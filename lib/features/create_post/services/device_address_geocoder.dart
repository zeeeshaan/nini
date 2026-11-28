import 'dart:ui';

import 'package:geocoding/geocoding.dart';
import 'package:hywork/features/create_post/services/address_geocoder.dart';

/// Uses the operating system's geocoder; it does not request GPS permission.
class DeviceAddressGeocoder implements AddressGeocoder {
  const DeviceAddressGeocoder();

  @override
  Future<String?> addressFromCoordinates(
    double latitude,
    double longitude, {
    required String languageCode,
  }) async {
    final placemarks = await Geocoding(locale: Locale(languageCode))
        .placemarkFromCoordinates(latitude, longitude);
    for (final place in placemarks) {
      final parts = <String>[];
      final seen = <String>{};
      for (final value in [
        place.street?.trim().isNotEmpty == true ? place.street : place.name,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ]) {
        final text = value?.trim() ?? '';
        if (text.isNotEmpty && seen.add(text.toLowerCase())) parts.add(text);
      }
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return null;
  }
}
