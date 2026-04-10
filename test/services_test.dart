import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maps_place_picker/src/services/places_service.dart';
import 'package:maps_place_picker/src/services/geocoding_service.dart';
import 'package:maps_place_picker/src/models/geocoding_result.dart';

// ───────────────────── helpers ────────────────────────────────────────────

http.Client _mockClient(int statusCode, Map<String, dynamic> body) =>
    MockClient((_) async => http.Response(
          jsonEncode(body),
          statusCode,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ));

// ─────────────────── PlacesService tests ──────────────────────────────────

void main() {
  group('PlacesService.autocomplete', () {
    test('returns predictions on 200 response', () async {
      final client = _mockClient(200, {
        'suggestions': [
          {
            'placePrediction': {
              'placeId': 'abc',
              'text': {
                'text': 'Paris, France',
                'matches': [
                  {'startOffset': 0, 'endOffset': 5}
                ],
              },
              'structuredFormat': {
                'mainText': {'text': 'Paris'},
                'secondaryText': {'text': 'France'},
              },
              'types': ['locality'],
            }
          }
        ]
      });

      final service =
          PlacesService(apiKey: 'key', httpClient: client);
      final response = await service.autocomplete('Paris');

      expect(response.status, 'OK');
      expect(response.predictions.length, 1);
      expect(response.predictions[0].placeId, 'abc');
      expect(response.predictions[0].description, 'Paris, France');
      expect(response.predictions[0].matchedSubstrings[0].offset, 0);
      expect(response.predictions[0].matchedSubstrings[0].length, 5);
    });

    test('returns REQUEST_DENIED on 403 response', () async {
      final client = _mockClient(403, {
        'error': {'message': 'API key invalid', 'code': 403}
      });

      final service =
          PlacesService(apiKey: 'key', httpClient: client);
      final response = await service.autocomplete('test');

      expect(response.status, 'REQUEST_DENIED');
      expect(response.errorMessage, contains('API key invalid'));
      expect(response.predictions, isEmpty);
    });

    test('empty suggestions list returns empty predictions', () async {
      final client = _mockClient(200, {'suggestions': []});
      final service =
          PlacesService(apiKey: 'key', httpClient: client);
      final response = await service.autocomplete('xyz');

      expect(response.status, 'OK');
      expect(response.predictions, isEmpty);
    });

    test('uses locationRestriction when strictbounds=true (B11)', () async {
      Uri? capturedUri;
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete(
        'test',
        latitude: 10.0,
        longitude: 20.0,
        radius: 500,
        strictbounds: true,
      );

      expect(capturedBody!.containsKey('locationRestriction'), isTrue);
      expect(capturedBody!.containsKey('locationBias'), isFalse);
    });

    test('uses locationBias when strictbounds=false (default)', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete(
        'test',
        latitude: 10.0,
        longitude: 20.0,
        radius: 500,
        strictbounds: false,
      );

      expect(capturedBody!.containsKey('locationBias'), isTrue);
      expect(capturedBody!.containsKey('locationRestriction'), isFalse);
    });

    test('sends regionCode for region parameter (B12)', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete('test', region: 'US');

      expect(capturedBody!['regionCode'], 'US');
    });
  });

  group('PlacesService.getDetailsByPlaceId', () {
    test('returns place details on 200 response', () async {
      final client = _mockClient(200, {
        'id': 'place123',
        'displayName': {'text': 'Eiffel Tower', 'languageCode': 'en'},
        'formattedAddress': 'Champ de Mars, Paris, France',
        'location': {'latitude': 48.8584, 'longitude': 2.2945},
        'rating': 4.7,
        'types': ['tourist_attraction'],
        'addressComponents': [
          {
            'longText': 'Paris',
            'shortText': 'Paris',
            'types': ['locality'],
          }
        ],
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      final response =
          await service.getDetailsByPlaceId('place123');

      expect(response.status, 'OK');
      expect(response.result, isNotNull);
      expect(response.result!.placeId, 'place123');
      expect(response.result!.name, 'Eiffel Tower');
      expect(response.result!.formattedAddress,
          'Champ de Mars, Paris, France');
      expect(response.result!.geometry!.location.lat, closeTo(48.8584, 0.001));
      expect(response.result!.rating, 4.7);
      expect(response.result!.addressComponents!.length, 1);
    });

    test('returns REQUEST_DENIED on auth error', () async {
      final client = _mockClient(403, {
        'error': {'message': 'Permission denied'}
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      final response = await service.getDetailsByPlaceId('x');

      expect(response.status, 'REQUEST_DENIED');
      expect(response.result, isNull);
    });
  });

  // ─────────────────── GeocodingService tests ───────────────────────────────

  group('GeocodingService.searchByLocation', () {
    test('returns results on OK response', () async {
      final client = _mockClient(200, {
        'status': 'OK',
        'results': [
          {
            'place_id': 'geo1',
            'formatted_address': '123 Rural Road',
            'types': ['route'],
            'geometry': {
              'location': {'lat': 5.0, 'lng': 6.0},
            },
            'address_components': [],
          }
        ]
      });

      final service =
          GeocodingService(apiKey: 'key', httpClient: client);
      final response = await service.searchByLocation(5.0, 6.0);

      expect(response.status, 'OK');
      expect(response.results.length, 1);
      expect(response.results[0].placeId, 'geo1');
      expect(response.results[0].geometry!.location.lat, 5.0);
    });

    test('returns ZERO_RESULTS status with empty list', () async {
      final client = _mockClient(200, {
        'status': 'ZERO_RESULTS',
        'results': [],
      });

      final service =
          GeocodingService(apiKey: 'key', httpClient: client);
      final response = await service.searchByLocation(0.0, 0.0);

      expect(response.results, isEmpty);
    });

    test('returns REQUEST_DENIED on 403', () async {
      final client = _mockClient(403, {});

      final service =
          GeocodingService(apiKey: 'key', httpClient: client);
      final response = await service.searchByLocation(0.0, 0.0);

      expect(response.status, 'REQUEST_DENIED');
      expect(response.results, isEmpty);
    });

    test('GeocodingResponse.isOk is true only for OK status', () {
      const ok = GeocodingResponse(status: 'OK', results: []);
      const denied = GeocodingResponse(status: 'REQUEST_DENIED', results: []);
      expect(ok.isOk, isTrue);
      expect(denied.isOk, isFalse);
    });
  });
}
