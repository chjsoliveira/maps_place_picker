import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maps_place_picker/src/models/geocoding_result.dart';

const _geocodingBaseUrl = 'https://maps.googleapis.com';

/// A lightweight HTTP client for the **Geocoding API**.
///
/// Used for reverse-geocoding the map camera position.
class GeocodingService {
  /// Creates a [GeocodingService].
  ///
  /// [apiKey] is required. [baseUrl] sets an optional proxy host. [httpClient]
  /// allows injecting a custom HTTP client (useful for testing).
  GeocodingService({
    required this.apiKey,
    this.baseUrl,
    http.Client? httpClient,
    Map<String, String>? apiHeaders,
  })  : _client = httpClient ?? http.Client(),
        _apiHeaders = apiHeaders ?? const {};

  /// Google Maps API key used to authenticate Geocoding API requests.
  final String apiKey;

  /// Optional proxy base URL. When set, every request will use this URL as the
  /// host instead of `https://maps.googleapis.com`.
  final String? baseUrl;

  final http.Client _client;
  final Map<String, String> _apiHeaders;

  String get _base => (baseUrl?.isNotEmpty == true)
      ? baseUrl!.replaceAll(RegExp(r'/$'), '')
      : _geocodingBaseUrl;

  /// Reverse-geocodes [latitude] / [longitude] using the Geocoding API.
  Future<GeocodingResponse> searchByLocation(
    double latitude,
    double longitude, {
    String? language,
  }) async {
    try {
      final queryParams = <String, String>{
        'latlng': '$latitude,$longitude',
        'key': apiKey,
        if (language != null) 'language': language,
      };

      final uri = Uri.parse('$_base/maps/api/geocode/json')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ..._apiHeaders,
        },
      );

      return _parseResponse(response);
    } catch (e) {
      return GeocodingResponse(
        status: 'NETWORK_ERROR',
        results: const [],
        errorMessage: e.toString(),
      );
    }
  }

  /// Forward-geocodes [address] using the Geocoding API.
  ///
  /// Returns a [GeocodingResponse] whose [GeocodingResponse.results] can be
  /// converted to [Prediction]s for display when the Places Autocomplete API
  /// returns no suggestions (see `geocodeOnTextFallback`).
  Future<GeocodingResponse> searchByAddress(
    String address, {
    String? language,
  }) async {
    try {
      final queryParams = <String, String>{
        'address': address,
        'key': apiKey,
        if (language != null) 'language': language,
      };

      final uri = Uri.parse('$_base/maps/api/geocode/json')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ..._apiHeaders,
        },
      );

      return _parseResponse(response);
    } catch (e) {
      return GeocodingResponse(
        status: 'NETWORK_ERROR',
        results: const [],
        errorMessage: e.toString(),
      );
    }
  }

  GeocodingResponse _parseResponse(http.Response response) {
    if (response.statusCode != 200) {
      return GeocodingResponse(
        status: 'REQUEST_DENIED',
        results: const [],
        errorMessage: 'HTTP ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? 'UNKNOWN';
    final errorMessage = body['error_message'] as String?;

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      return GeocodingResponse(
        status: status,
        results: const [],
        errorMessage: errorMessage,
      );
    }

    final results = (body['results'] as List<dynamic>? ?? const [])
        .map((e) => GeocodingResult.fromJson(e as Map<String, dynamic>))
        .toList();

    return GeocodingResponse(
      status: status.isEmpty ? 'OK' : status,
      results: results,
    );
  }
}
