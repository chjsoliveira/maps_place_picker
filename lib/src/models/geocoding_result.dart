import 'package:maps_place_picker/src/models/address_component.dart';
import 'package:maps_place_picker/src/models/geometry.dart';

/// A single result from a Geocoding API reverse-geocode lookup.
class GeocodingResult {
  /// Creates a [GeocodingResult] with the given fields.
  const GeocodingResult({
    required this.placeId,
    this.geometry,
    this.formattedAddress,
    this.types,
    this.addressComponents,
  });

  /// The unique Place ID for this result.
  final String placeId;

  /// Geographic location and viewport for the result.
  final Geometry? geometry;

  /// Human-readable formatted address.
  final String? formattedAddress;

  /// Place-type strings (e.g. `["street_address"]`).
  final List<String>? types;

  /// Structured address components.
  final List<AddressComponent>? addressComponents;

  /// Parses a [GeocodingResult] from the Geocoding API JSON format.
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
  /// Creates a [GeocodingResponse] with the given [status], [results], and
  /// optional [errorMessage].
  const GeocodingResponse({
    required this.status,
    required this.results,
    this.errorMessage,
  });

  /// The API response status string (e.g. `"OK"`, `"ZERO_RESULTS"`).
  final String status;

  /// List of geocoding results; empty when [status] is not `"OK"`.
  final List<GeocodingResult> results;

  /// Optional human-readable error message returned by the API.
  final String? errorMessage;

  /// Whether the response indicates a successful lookup.
  bool get isOk => status == 'OK';
}
