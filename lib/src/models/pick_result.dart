import 'package:maps_place_picker/src/models/address_component.dart';
import 'package:maps_place_picker/src/models/geometry.dart';
import 'package:maps_place_picker/src/models/geocoding_result.dart';
import 'package:maps_place_picker/src/models/place_details.dart';

export 'package:maps_place_picker/src/models/address_component.dart';
export 'package:maps_place_picker/src/models/geometry.dart';
export 'package:maps_place_picker/src/models/place_details.dart';

/// The result returned when the user picks a location in [PlacePicker].
///
/// When [PlacePicker.usePlaceDetailSearch] is `false` (the default), only
/// [placeId], [geometry], [formattedAddress], [types], and
/// [addressComponents] are populated. All other fields require
/// `usePlaceDetailSearch: true`.
class PickResult {
  PickResult({
    this.placeId,
    this.geometry,
    this.formattedAddress,
    this.types,
    this.addressComponents,
    this.adrAddress,
    this.formattedPhoneNumber,
    this.name,
    this.openingHours,
    this.photos,
    this.internationalPhoneNumber,
    this.priceLevel,
    this.rating,
    this.url,
    this.vicinity,
    this.website,
    this.reviews,
  });

  final String? placeId;
  final Geometry? geometry;
  final String? formattedAddress;
  final List<String>? types;
  final List<AddressComponent>? addressComponents;

  // The fields below are only populated when usePlaceDetailSearch = true.

  final String? adrAddress;
  final String? formattedPhoneNumber;
  final String? name;
  final OpeningHoursDetail? openingHours;
  final List<Photo>? photos;
  final String? internationalPhoneNumber;
  final PriceLevel? priceLevel;
  final num? rating;
  final String? url;
  final String? vicinity;
  final String? website;
  final List<Review>? reviews;

  // ──────────────────────── Convenience getters ──────────────────────────

  /// The street number component of the address, or `null` if not present.
  ///
  /// Returns the `longName` of the first [AddressComponent] whose [types]
  /// contains `"street_number"`. Returns `null` when [addressComponents] is
  /// `null` or no matching component exists.
  String? get streetNumber {
    if (addressComponents == null) return null;
    for (final c in addressComponents!) {
      if (c.types.contains('street_number') && c.longName.isNotEmpty) {
        return c.longName;
      }
    }
    return null;
  }

  /// The postal code component of the address, or `null` if not present.
  ///
  /// Returns the `longName` of the first [AddressComponent] whose [types]
  /// contains `"postal_code"`. Returns `null` when [addressComponents] is
  /// `null` or no matching component exists.
  String? get postalCode {
    if (addressComponents == null) return null;
    for (final c in addressComponents!) {
      if (c.types.contains('postal_code') && c.longName.isNotEmpty) {
        return c.longName;
      }
    }
    return null;
  }

  /// Creates a [PickResult] from a reverse-geocoding [GeocodingResult].
  ///
  /// [cameraLat] and [cameraLng] are the exact pin position from the map
  /// camera. They are used as the authoritative coordinates (B16 fix: the
  /// geocoding result may return a centroid that does not match the pin in
  /// rural / low-density areas).
  factory PickResult.fromGeocodingResult(
    GeocodingResult result, {
    double? cameraLat,
    double? cameraLng,
  }) {
    final Geometry? resolvedGeometry = (cameraLat != null && cameraLng != null)
        ? Geometry.fromCameraAndGeocoding(
            lat: cameraLat,
            lng: cameraLng,
            viewport: result.geometry?.viewport,
          )
        : result.geometry;

    return PickResult(
      placeId: result.placeId,
      geometry: resolvedGeometry,
      formattedAddress: result.formattedAddress,
      types: result.types,
      addressComponents: result.addressComponents,
    );
  }

  /// Creates a [PickResult] from a [PlaceDetails] response (used when
  /// [PlacePicker.usePlaceDetailSearch] is `true`).
  factory PickResult.fromPlaceDetailResult(PlaceDetails result) {
    return PickResult(
      placeId: result.placeId,
      geometry: result.geometry,
      formattedAddress: result.formattedAddress,
      types: result.types,
      addressComponents: result.addressComponents,
      adrAddress: result.adrAddress,
      formattedPhoneNumber: result.formattedPhoneNumber,
      name: result.name,
      openingHours: result.openingHours,
      photos: result.photos,
      internationalPhoneNumber: result.internationalPhoneNumber,
      priceLevel: result.priceLevel,
      rating: result.rating,
      url: result.url,
      vicinity: result.vicinity,
      website: result.website,
      reviews: result.reviews,
    );
  }
}
