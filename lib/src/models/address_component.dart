/// A component of a formatted address, as returned by the Places /
/// Geocoding APIs.
class AddressComponent {
  /// Creates an [AddressComponent] with [longName], [shortName], and [types].
  const AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  /// Full text of the address component (e.g. "United States").
  final String longName;

  /// Abbreviated text of the address component (e.g. "US").
  final String shortName;

  /// Place types applicable to this component.
  final List<String> types;

  /// Parses the classic Geocoding / Places API v1 format.
  factory AddressComponent.fromGeocodingJson(Map<String, dynamic> json) =>
      AddressComponent(
        longName: (json['long_name'] as String?) ?? '',
        shortName: (json['short_name'] as String?) ?? '',
        types: (json['types'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

  /// Parses the Places API (New) format which uses `longText` / `shortText`.
  factory AddressComponent.fromNewApiJson(Map<String, dynamic> json) =>
      AddressComponent(
        longName: (json['longText'] as String?) ?? '',
        shortName: (json['shortText'] as String?) ?? '',
        types: (json['types'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}
