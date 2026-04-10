import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maps_place_picker/src/models/address_component.dart';
import 'package:maps_place_picker/src/models/component.dart';
import 'package:maps_place_picker/src/models/geometry.dart';
import 'package:maps_place_picker/src/models/place_details.dart';
import 'package:maps_place_picker/src/models/prediction.dart';

const _defaultPlacesBaseUrl = 'https://places.googleapis.com';

/// Response from the Places API (New) autocomplete endpoint.
class PlacesAutocompleteResponse {
  /// Creates a [PlacesAutocompleteResponse] with [status] and [predictions].
  const PlacesAutocompleteResponse({
    required this.status,
    required this.predictions,
    this.errorMessage,
  });

  /// HTTP-derived status: `"OK"` on success, `"REQUEST_DENIED"` on auth
  /// failure, or an HTTP status code string on network error.
  final String status;

  /// List of autocomplete suggestions; empty when the request failed.
  final List<Prediction> predictions;

  /// Optional human-readable error message.
  final String? errorMessage;

  /// Whether the response indicates a successful request.
  bool get isOk => status == 'OK';
}

/// Response from the Places API (New) place-details endpoint.
class PlacesDetailsResponse {
  /// Creates a [PlacesDetailsResponse] with [status] and optional [result].
  const PlacesDetailsResponse({
    required this.status,
    this.result,
    this.errorMessage,
  });

  /// API status string (e.g. `"OK"`, `"REQUEST_DENIED"`).
  final String status;

  /// The [PlaceDetails] result, or `null` if the request failed.
  final PlaceDetails? result;

  /// Optional human-readable error message.
  final String? errorMessage;

  /// Whether the response indicates a successful request.
  bool get isOk => status == 'OK';
}

/// A lightweight HTTP client for the **Places API (New)**.
///
/// Replaces the unmaintained `flutter_google_maps_webservices` package.
///
/// Supported operations:
/// - [autocomplete] – Places Autocomplete (New)
/// - [getDetailsByPlaceId] – Place Details (New)
class PlacesService {
  /// Creates a [PlacesService].
  ///
  /// [apiKey] is required. [baseUrl] sets an optional proxy host. [httpClient]
  /// allows injecting a custom HTTP client (useful for testing).
  PlacesService({
    required this.apiKey,
    this.baseUrl,
    http.Client? httpClient,
    Map<String, String>? apiHeaders,
  })  : _client = httpClient ?? http.Client(),
        _apiHeaders = apiHeaders ?? const {};

  /// Google Maps API key used to authenticate Places API requests.
  final String apiKey;
  final String? baseUrl;

  final http.Client _client;
  final Map<String, String> _apiHeaders;

  String get _base => (baseUrl?.isNotEmpty == true)
      ? baseUrl!.replaceAll(RegExp(r'/$'), '')
      : _defaultPlacesBaseUrl;

  Map<String, String> _headers({String? fieldMask}) => {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        if (fieldMask != null) 'X-Goog-FieldMask': fieldMask,
        ..._apiHeaders,
      };

  // ─────────────────────────── Autocomplete ──────────────────────────────

  /// Fetches autocomplete predictions for [input].
  ///
  /// [strictbounds] – when `true` and both [location] and [radius] are
  /// provided, results are restricted to the specified circle
  /// (`locationRestriction`). When `false` the circle is used only as a bias
  /// (`locationBias`).  This fixes upstream issue B11.
  ///
  /// [region] – a CLDR two-character region code used to bias results (fixes
  /// upstream issue B12 – previously passed but had no effect in v1; now
  /// maps to `regionCode` in the New API).
  Future<PlacesAutocompleteResponse> autocomplete(
    String input, {
    String? sessionToken,
    double? latitude,
    double? longitude,
    num? radius,
    String? language,
    List<String>? types,
    List<Component>? components,
    bool strictbounds = false,
    String? region,
    num? offset,
  }) async {
    try {
      final body = <String, dynamic>{
        'input': input,
        if (sessionToken != null) 'sessionToken': sessionToken,
        if (language != null) 'languageCode': language,
        if (offset != null) 'inputOffset': offset.toInt(),
      };

      // B11: use locationRestriction (hard boundary) when strictbounds=true,
      // otherwise use locationBias (soft preference).
      if (latitude != null && longitude != null && radius != null) {
        final circle = {
          'circle': {
            'center': {'latitude': latitude, 'longitude': longitude},
            'radius': radius.toDouble(),
          },
        };
        if (strictbounds) {
          body['locationRestriction'] = circle;
        } else {
          body['locationBias'] = circle;
        }
      }

      // B12: region is now correctly sent as `regionCode` to the New API.
      if (region != null) body['regionCode'] = region;

      // Extract country codes from Component list for includedRegionCodes.
      if (components != null && components.isNotEmpty) {
        final countryCodes = components
            .where((c) => c.component == Component.country)
            .map((c) => c.value)
            .toList();
        if (countryCodes.isNotEmpty) {
          body['includedRegionCodes'] = countryCodes;
        }
      }

      if (types != null && types.isNotEmpty) {
        body['includedPrimaryTypes'] = types;
      }

      const fieldMask =
          'suggestions.placePrediction.placeId,'
          'suggestions.placePrediction.text,'
          'suggestions.placePrediction.structuredFormat,'
          'suggestions.placePrediction.types';

      final uri = Uri.parse('$_base/v1/places:autocomplete');
      final response = await _client.post(
        uri,
        headers: _headers(fieldMask: fieldMask),
        body: jsonEncode(body),
      );

      return _parseAutocompleteResponse(response);
    } catch (e) {
      return PlacesAutocompleteResponse(
        status: 'NETWORK_ERROR',
        predictions: const [],
        errorMessage: e.toString(),
      );
    }
  }

  PlacesAutocompleteResponse _parseAutocompleteResponse(
      http.Response response) {
    if (response.statusCode != 200) {
      String? errorMsg;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg =
            (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      } catch (_) {}
      return PlacesAutocompleteResponse(
        status: 'REQUEST_DENIED',
        predictions: const [],
        errorMessage: errorMsg ?? 'HTTP ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = body['suggestions'] as List<dynamic>? ?? const [];

    final predictions = suggestions
        .map((s) {
          final pp = (s as Map<String, dynamic>)['placePrediction']
              as Map<String, dynamic>?;
          if (pp == null) return null;
          return Prediction.fromNewApiJson(pp);
        })
        .whereType<Prediction>()
        .toList();

    return PlacesAutocompleteResponse(
      status: 'OK',
      predictions: predictions,
    );
  }

  // ─────────────────────────── Place Details ─────────────────────────────

  static const _detailFieldMask =
      'id,'
      'displayName,'
      'formattedAddress,'
      'shortFormattedAddress,'
      'location,'
      'addressComponents,'
      'adrFormatAddress,'
      'internationalPhoneNumber,'
      'nationalPhoneNumber,'
      'rating,'
      'priceLevel,'
      'websiteUri,'
      'googleMapsUri,'
      'regularOpeningHours,'
      'photos,'
      'reviews,'
      'types';

  /// Fetches full place details for [placeId].
  Future<PlacesDetailsResponse> getDetailsByPlaceId(
    String placeId, {
    String? sessionToken,
    String? language,
  }) async {
    try {
      final queryParams = <String, String>{
        'key': apiKey,
        if (language != null) 'languageCode': language,
        if (sessionToken != null) 'sessionToken': sessionToken,
      };

      final uri = Uri.parse('$_base/v1/places/$placeId')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: _headers(fieldMask: _detailFieldMask),
      );

      return _parsePlaceDetailsResponse(response);
    } catch (e) {
      return PlacesDetailsResponse(
        status: 'NETWORK_ERROR',
        errorMessage: e.toString(),
      );
    }
  }

  // ─────────────────────────── Nearby Search ─────────────────────────────

  /// Searches for places near a given location using the Places API (New)
  /// Nearby Search endpoint.
  ///
  /// [latitude] and [longitude] define the center of the search area.
  /// [radius] is the search radius in metres (default 500 m).
  /// [language] is the optional BCP-47 language code for result localisation.
  /// [types] is an optional list of place types to filter by (e.g.
  /// `["restaurant", "cafe"]`).
  /// [maxResults] caps the number of results returned (default 10).
  ///
  /// Returns a [PlacesAutocompleteResponse] where each [Prediction] has
  /// [Prediction.placeId] set to the place's ID and [Prediction.description]
  /// set to the place's display name.
  ///
  /// Example:
  /// ```dart
  /// final response = await places.searchNearby(37.422, -122.084,
  ///     radius: 1000, types: ['restaurant']);
  /// for (final p in response.predictions) {
  ///   print('${p.description} (${p.placeId})');
  /// }
  /// ```
  Future<PlacesAutocompleteResponse> searchNearby(
    double latitude,
    double longitude, {
    double radius = 500.0,
    String? language,
    List<String>? types,
    int maxResults = 10,
  }) async {
    try {
      final body = <String, dynamic>{
        'locationRestriction': {
          'circle': {
            'center': {'latitude': latitude, 'longitude': longitude},
            'radius': radius,
          },
        },
        'maxResultCount': maxResults,
        if (language != null) 'languageCode': language,
        if (types != null && types.isNotEmpty) 'includedTypes': types,
      };

      const fieldMask =
          'places.id,'
          'places.displayName,'
          'places.formattedAddress';

      final uri = Uri.parse('$_base/v1/places:searchNearby');
      final response = await _client.post(
        uri,
        headers: _headers(fieldMask: fieldMask),
        body: jsonEncode(body),
      );

      return _parseNearbySearchResponse(response);
    } catch (e) {
      return PlacesAutocompleteResponse(
        status: 'NETWORK_ERROR',
        predictions: const [],
        errorMessage: e.toString(),
      );
    }
  }

  PlacesAutocompleteResponse _parseNearbySearchResponse(
      http.Response response) {
    if (response.statusCode != 200) {
      String? errorMsg;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg =
            (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      } catch (_) {}
      return PlacesAutocompleteResponse(
        status: 'REQUEST_DENIED',
        predictions: const [],
        errorMessage: errorMsg ?? 'HTTP ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final places = body['places'] as List<dynamic>? ?? const [];

    final predictions = places
        .map((p) {
          final place = p as Map<String, dynamic>;
          final id = place['id'] as String?;
          if (id == null) return null;
          final displayName =
              (place['displayName'] as Map<String, dynamic>?)?['text']
                  as String?;
          return Prediction(
            placeId: id,
            description: displayName,
          );
        })
        .whereType<Prediction>()
        .toList();

    return PlacesAutocompleteResponse(
      status: 'OK',
      predictions: predictions,
    );
  }

  PlacesDetailsResponse _parsePlaceDetailsResponse(http.Response response) {
    if (response.statusCode != 200) {
      String? errorMsg;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg =
            (body['error'] as Map<String, dynamic>?)?['message'] as String?;
      } catch (_) {}
      return PlacesDetailsResponse(
        status: 'REQUEST_DENIED',
        errorMessage: errorMsg ?? 'HTTP ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final locationJson = json['location'] as Map<String, dynamic>?;
    final Geometry? geometry = locationJson != null
        ? Geometry(
            location: Location.fromNewApiJson(locationJson),
          )
        : null;

    final details = PlaceDetails(
      placeId: json['id'] as String?,
      name: (json['displayName'] as Map<String, dynamic>?)?['text'] as String?,
      formattedAddress: json['formattedAddress'] as String?,
      shortFormattedAddress: json['shortFormattedAddress'] as String?,
      geometry: geometry,
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      addressComponents:
          (json['addressComponents'] as List<dynamic>?)
              ?.map((e) => AddressComponent.fromNewApiJson(
                  e as Map<String, dynamic>))
              .toList(),
      adrAddress: json['adrFormatAddress'] as String?,
      internationalPhoneNumber:
          json['internationalPhoneNumber'] as String?,
      formattedPhoneNumber: json['nationalPhoneNumber'] as String?,
      rating: json['rating'] as num?,
      priceLevel: parsePriceLevel(json['priceLevel'] as String?),
      url: json['googleMapsUri'] as String?,
      vicinity: json['shortFormattedAddress'] as String?,
      website: json['websiteUri'] as String?,
      openingHours: json['regularOpeningHours'] != null
          ? OpeningHoursDetail.fromJson(
              json['regularOpeningHours'] as Map<String, dynamic>)
          : null,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    return PlacesDetailsResponse(status: 'OK', result: details);
  }
}
