import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maps_place_picker/src/models/component.dart';
import 'package:maps_place_picker/src/services/geocoding_service.dart';
import 'package:maps_place_picker/src/services/places_service.dart';

// ─────────────────────────── helpers ──────────────────────────────────────

http.Client _mockClient(int statusCode, Map<String, dynamic> body) =>
    MockClient((_) async => http.Response(
          jsonEncode(body),
          statusCode,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ));

/// A client that always throws a [SocketException]-like error.
http.Client _throwingClient() =>
    MockClient((_) async => throw Exception('Network unreachable'));

// ─────────────────────── PlacesService edge cases ─────────────────────────

void main() {
  group('PlacesService – NETWORK_ERROR', () {
    test('returns NETWORK_ERROR status when HTTP throws', () async {
      final service =
          PlacesService(apiKey: 'key', httpClient: _throwingClient());
      final response = await service.autocomplete('test');

      expect(response.status, 'NETWORK_ERROR');
      expect(response.predictions, isEmpty);
      expect(response.errorMessage, isNotNull);
    });

    test('getDetailsByPlaceId returns NETWORK_ERROR when HTTP throws',
        () async {
      final service =
          PlacesService(apiKey: 'key', httpClient: _throwingClient());
      final response = await service.getDetailsByPlaceId('place1');

      expect(response.status, 'NETWORK_ERROR');
      expect(response.result, isNull);
      expect(response.errorMessage, isNotNull);
    });
  });

  group('PlacesService – proxy baseUrl', () {
    test('autocomplete uses custom baseUrl', () async {
      Uri? capturedUri;

      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(
        apiKey: 'key',
        baseUrl: 'https://proxy.example.com',
        httpClient: client,
      );

      await service.autocomplete('test');

      expect(capturedUri!.host, 'proxy.example.com');
      expect(capturedUri!.path, '/v1/places:autocomplete');
    });

    test('getDetailsByPlaceId uses custom baseUrl', () async {
      Uri? capturedUri;

      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({'id': 'p1', 'location': null}),
          200,
        );
      });

      final service = PlacesService(
        apiKey: 'key',
        baseUrl: 'https://proxy.example.com/',
        httpClient: client,
      );

      await service.getDetailsByPlaceId('p1');

      expect(capturedUri!.host, 'proxy.example.com');
      expect(capturedUri!.path, '/v1/places/p1');
    });
  });

  group('PlacesService – autocomplete request body', () {
    test('sends includedPrimaryTypes when types provided', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete('cafe', types: ['cafe', 'restaurant']);

      expect(capturedBody!['includedPrimaryTypes'], ['cafe', 'restaurant']);
    });

    test('sends includedRegionCodes from Component country list', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete(
        'test',
        components: [
          const Component(Component.country, 'us'),
          const Component(Component.country, 'ca'),
        ],
      );

      expect(capturedBody!['includedRegionCodes'], containsAll(['us', 'ca']));
    });

    test('ignores non-country components for includedRegionCodes', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete(
        'test',
        components: [const Component('region', 'eu')],
      );

      expect(capturedBody!.containsKey('includedRegionCodes'), isFalse);
    });

    test('sends sessionToken when provided', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete('test', sessionToken: 'tok123');

      expect(capturedBody!['sessionToken'], 'tok123');
    });

    test('sends languageCode when provided', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete('test', language: 'pt-BR');

      expect(capturedBody!['languageCode'], 'pt-BR');
    });

    test('sends inputOffset when offset provided', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete('test', offset: 3);

      expect(capturedBody!['inputOffset'], 3);
    });

    test('does not send location bias when coordinates absent', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      await service.autocomplete('test');

      expect(capturedBody!.containsKey('locationBias'), isFalse);
      expect(capturedBody!.containsKey('locationRestriction'), isFalse);
    });
  });

  group('PlacesService – getDetailsByPlaceId response parsing', () {
    test('returns null geometry when location field is absent', () async {
      final client = _mockClient(200, {
        'id': 'p1',
        'formattedAddress': 'Unknown Place',
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      final response = await service.getDetailsByPlaceId('p1');

      expect(response.status, 'OK');
      expect(response.result!.geometry, isNull);
    });

    test('parses photos list', () async {
      final client = _mockClient(200, {
        'id': 'p1',
        'location': {'latitude': 10.0, 'longitude': 20.0},
        'photos': [
          {'name': 'places/p1/photos/ref1', 'widthPx': 800, 'heightPx': 600},
          {'name': 'places/p1/photos/ref2', 'widthPx': 1024, 'heightPx': 768},
        ],
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      final response = await service.getDetailsByPlaceId('p1');

      expect(response.result!.photos, hasLength(2));
      expect(response.result!.photos![0].photoReference,
          'places/p1/photos/ref1');
      expect(response.result!.photos![0].width, 800);
    });

    test('parses reviews list', () async {
      final client = _mockClient(200, {
        'id': 'p1',
        'location': {'latitude': 0.0, 'longitude': 0.0},
        'reviews': [
          {
            'authorAttribution': {
              'displayName': 'Bob',
              'photoUri': '',
              'uri': ''
            },
            'text': {'text': 'Excellent!', 'languageCode': 'en'},
            'rating': 5,
            'relativePublishTimeDescription': 'a week ago',
            'publishTime': '2024-03-01T10:00:00Z',
          }
        ],
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      final response = await service.getDetailsByPlaceId('p1');

      expect(response.result!.reviews, hasLength(1));
      expect(response.result!.reviews![0].authorName, 'Bob');
      expect(response.result!.reviews![0].text, 'Excellent!');
    });

    test('parses opening hours', () async {
      final client = _mockClient(200, {
        'id': 'p1',
        'location': {'latitude': 0.0, 'longitude': 0.0},
        'regularOpeningHours': {
          'openNow': true,
          'periods': [
            {
              'open': {'day': 1, 'hour': 9, 'minute': 0},
              'close': {'day': 1, 'hour': 18, 'minute': 0},
            }
          ],
          'weekdayDescriptions': ['Monday: 9 AM - 6 PM'],
        },
      });

      final service = PlacesService(apiKey: 'key', httpClient: client);
      final response = await service.getDetailsByPlaceId('p1');

      expect(response.result!.openingHours, isNotNull);
      expect(response.result!.openingHours!.openNow, isTrue);
      expect(response.result!.openingHours!.weekdayText, hasLength(1));
    });

    test('sends X-Goog-Api-Key header', () async {
      Map<String, String>? capturedHeaders;

      final client = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response(
            jsonEncode({'id': 'p1', 'location': null}), 200);
      });

      final service = PlacesService(apiKey: 'my_secret_key', httpClient: client);
      await service.getDetailsByPlaceId('p1');

      expect(capturedHeaders!['X-Goog-Api-Key'], 'my_secret_key');
    });
  });

  group('PlacesService – isOk helpers', () {
    test('PlacesAutocompleteResponse.isOk is true only for OK', () {
      const ok = PlacesAutocompleteResponse(status: 'OK', predictions: []);
      const denied =
          PlacesAutocompleteResponse(status: 'REQUEST_DENIED', predictions: []);
      expect(ok.isOk, isTrue);
      expect(denied.isOk, isFalse);
    });

    test('PlacesDetailsResponse.isOk is true only for OK', () {
      const ok = PlacesDetailsResponse(status: 'OK');
      const denied = PlacesDetailsResponse(status: 'REQUEST_DENIED');
      expect(ok.isOk, isTrue);
      expect(denied.isOk, isFalse);
    });
  });

  // ─────────────────── GeocodingService edge cases ──────────────────────────

  group('GeocodingService – NETWORK_ERROR', () {
    test('returns NETWORK_ERROR when HTTP throws', () async {
      final service =
          GeocodingService(apiKey: 'key', httpClient: _throwingClient());
      final response = await service.searchByLocation(0.0, 0.0);

      expect(response.status, 'NETWORK_ERROR');
      expect(response.results, isEmpty);
      expect(response.errorMessage, isNotNull);
    });
  });

  group('GeocodingService – request parameters', () {
    test('sends language query parameter when provided', () async {
      Uri? capturedUri;

      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
            jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final service = GeocodingService(apiKey: 'key', httpClient: client);
      await service.searchByLocation(1.0, 2.0, language: 'pt');

      expect(capturedUri!.queryParameters['language'], 'pt');
    });

    test('does not send language when absent', () async {
      Uri? capturedUri;

      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
            jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final service = GeocodingService(apiKey: 'key', httpClient: client);
      await service.searchByLocation(1.0, 2.0);

      expect(capturedUri!.queryParameters.containsKey('language'), isFalse);
    });

    test('sends correct latlng parameter', () async {
      Uri? capturedUri;

      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
            jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final service = GeocodingService(apiKey: 'key', httpClient: client);
      await service.searchByLocation(48.8566, 2.3522);

      expect(capturedUri!.queryParameters['latlng'], '48.8566,2.3522');
    });
  });

  group('GeocodingService – response parsing', () {
    test('returns error from body when status is not OK or ZERO_RESULTS',
        () async {
      final client = _mockClient(200, {
        'status': 'REQUEST_DENIED',
        'error_message': 'API key missing',
        'results': [],
      });

      final service = GeocodingService(apiKey: 'key', httpClient: client);
      final response = await service.searchByLocation(0.0, 0.0);

      expect(response.status, 'REQUEST_DENIED');
      expect(response.errorMessage, 'API key missing');
      expect(response.results, isEmpty);
    });

    test('parses multiple results', () async {
      final client = _mockClient(200, {
        'status': 'OK',
        'results': [
          {
            'place_id': 'r1',
            'formatted_address': 'Result 1',
            'geometry': {
              'location': {'lat': 1.0, 'lng': 2.0}
            },
          },
          {
            'place_id': 'r2',
            'formatted_address': 'Result 2',
            'geometry': {
              'location': {'lat': 3.0, 'lng': 4.0}
            },
          },
        ],
      });

      final service = GeocodingService(apiKey: 'key', httpClient: client);
      final response = await service.searchByLocation(1.0, 2.0);

      expect(response.results, hasLength(2));
      expect(response.results[0].placeId, 'r1');
      expect(response.results[1].placeId, 'r2');
    });

    test('uses custom baseUrl', () async {
      Uri? capturedUri;

      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
            jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final service = GeocodingService(
        apiKey: 'key',
        baseUrl: 'https://geo-proxy.example.com',
        httpClient: client,
      );
      await service.searchByLocation(0.0, 0.0);

      expect(capturedUri!.host, 'geo-proxy.example.com');
    });

    test('apiHeaders are forwarded in request', () async {
      Map<String, String>? capturedHeaders;

      final client = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response(
            jsonEncode({'status': 'OK', 'results': []}), 200);
      });

      final service = GeocodingService(
        apiKey: 'key',
        httpClient: client,
        apiHeaders: {'X-Custom-Header': 'test-value'},
      );
      await service.searchByLocation(0.0, 0.0);

      expect(capturedHeaders!['X-Custom-Header'], 'test-value');
    });
  });
}
