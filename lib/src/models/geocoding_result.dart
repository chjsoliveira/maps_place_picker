import 'package:maps_place_picker/src/models/address_component.dart';
import 'package:maps_place_picker/src/models/geometry.dart';

/// A single result from a Geocoding API reverse-geocode lookup.
class GeocodingResult {
  const GeocodingResult({
    required this.placeId,
    this.geometry,
    this.formattedAddress,
    this.types,
    this.addressComponents,
  });

  final String placeId;
  final Geometry? geometry;
  final String? formattedAddress;
  final List<String>? types;
  final List<AddressComponent>? addressComponents;

  factory GeocodingResult.fromJson(Map<String, dynamic> json) =>
      GeocodingResult(
        placeId: json['place_id'] as String? ?? '',
        geometry: json['geometry'] != null
            ? Geometry.fromGeocodingJson(
                json['geometry'] as Map<String, dynamic>)
            : null,
        formattedAddress: json['formatted_address'] as String?,
        types: (json['types'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        addressComponents: (json['address_components'] as List<dynamic>?)
            ?.map((e) => AddressComponent.fromGeocodingJson(
                e as Map<String, dynamic>))
            .toList(),
      );
}

/// Response wrapper returned by [GeocodingService].
class GeocodingResponse {
  const GeocodingResponse({
    required this.status,
    required this.results,
    this.errorMessage,
  });

  final String status;
  final List<GeocodingResult> results;
  final String? errorMessage;

  bool get isOk => status == 'OK';
}
