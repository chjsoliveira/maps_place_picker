/// Geographic coordinates returned by the Places and Geocoding APIs.
class Location {
  const Location({required this.lat, required this.lng});

  /// Latitude in decimal degrees.
  final double lat;

  /// Longitude in decimal degrees.
  final double lng;

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  /// Parses a location returned by the Places API (New) which uses
  /// `latitude` / `longitude` keys instead of `lat` / `lng`.
  factory Location.fromNewApiJson(Map<String, dynamic> json) => Location(
        lat: (json['latitude'] as num).toDouble(),
        lng: (json['longitude'] as num).toDouble(),
      );
}

/// A bounding box defined by a north-east and south-west corner.
class Bounds {
  const Bounds({required this.northeast, required this.southwest});

  final Location northeast;
  final Location southwest;

  factory Bounds.fromJson(Map<String, dynamic> json) => Bounds(
        northeast: Location.fromJson(json['northeast'] as Map<String, dynamic>),
        southwest: Location.fromJson(json['southwest'] as Map<String, dynamic>),
      );
}

/// Location geometry as returned by the Places / Geocoding APIs.
///
/// [location] is the representative point for the place.
/// [viewport] is the recommended viewport for displaying the place on a map.
class Geometry {
  const Geometry({required this.location, this.viewport});

  final Location location;
  final Bounds? viewport;

  factory Geometry.fromGeocodingJson(Map<String, dynamic> json) => Geometry(
        location:
            Location.fromJson(json['location'] as Map<String, dynamic>),
        viewport: json['viewport'] != null
            ? Bounds.fromJson(json['viewport'] as Map<String, dynamic>)
            : null,
      );

  /// Creates a [Geometry] using the camera pin position as the authoritative
  /// location (used for Sprint 4 B16 fix) with an optional viewport from the
  /// geocoding result.
  factory Geometry.fromCameraAndGeocoding({
    required double lat,
    required double lng,
    Bounds? viewport,
  }) =>
      Geometry(
        location: Location(lat: lat, lng: lng),
        viewport: viewport,
      );
}
