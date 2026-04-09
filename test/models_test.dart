import 'package:flutter_test/flutter_test.dart';
import 'package:maps_place_picker/src/models/address_component.dart';
import 'package:maps_place_picker/src/models/geometry.dart';
import 'package:maps_place_picker/src/models/geocoding_result.dart';
import 'package:maps_place_picker/src/models/place_details.dart';
import 'package:maps_place_picker/src/models/prediction.dart';
import 'package:maps_place_picker/src/models/pick_result.dart';

void main() {
  group('Location', () {
    test('fromJson parses lat/lng keys', () {
      final loc = Location.fromJson({'lat': 37.422, 'lng': -122.084});
      expect(loc.lat, 37.422);
      expect(loc.lng, -122.084);
    });

    test('fromNewApiJson parses latitude/longitude keys', () {
      final loc = Location.fromNewApiJson(
          {'latitude': 37.422, 'longitude': -122.084});
      expect(loc.lat, 37.422);
      expect(loc.lng, -122.084);
    });
  });

  group('Geometry', () {
    test('fromGeocodingJson parses location and viewport', () {
      final geo = Geometry.fromGeocodingJson({
        'location': {'lat': 1.0, 'lng': 2.0},
        'viewport': {
          'northeast': {'lat': 1.1, 'lng': 2.1},
          'southwest': {'lat': 0.9, 'lng': 1.9},
        },
      });
      expect(geo.location.lat, 1.0);
      expect(geo.location.lng, 2.0);
      expect(geo.viewport, isNotNull);
      expect(geo.viewport!.northeast.lat, 1.1);
    });

    test('fromGeocodingJson handles missing viewport', () {
      final geo = Geometry.fromGeocodingJson(
          {'location': {'lat': 1.0, 'lng': 2.0}});
      expect(geo.viewport, isNull);
    });

    test('fromCameraAndGeocoding overrides location', () {
      final geo = Geometry.fromCameraAndGeocoding(lat: 5.0, lng: 6.0);
      expect(geo.location.lat, 5.0);
      expect(geo.location.lng, 6.0);
    });
  });

  group('AddressComponent', () {
    test('fromGeocodingJson parses long_name / short_name', () {
      final ac = AddressComponent.fromGeocodingJson({
        'long_name': 'United States',
        'short_name': 'US',
        'types': ['country', 'political'],
      });
      expect(ac.longName, 'United States');
      expect(ac.shortName, 'US');
      expect(ac.types, ['country', 'political']);
    });

    test('fromNewApiJson parses longText / shortText', () {
      final ac = AddressComponent.fromNewApiJson({
        'longText': 'Brazil',
        'shortText': 'BR',
        'types': ['country'],
      });
      expect(ac.longName, 'Brazil');
      expect(ac.shortName, 'BR');
    });

    test('handles missing fields gracefully', () {
      final ac = AddressComponent.fromGeocodingJson({});
      expect(ac.longName, '');
      expect(ac.shortName, '');
      expect(ac.types, isEmpty);
    });
  });

  group('MatchedSubstring', () {
    test('fromJson parses offset/length', () {
      final m = MatchedSubstring.fromJson({'offset': 3, 'length': 5});
      expect(m.offset, 3);
      expect(m.length, 5);
    });

    test('fromNewApiJson converts startOffset/endOffset', () {
      final m =
          MatchedSubstring.fromNewApiJson({'startOffset': 2, 'endOffset': 7});
      expect(m.offset, 2);
      expect(m.length, 5);
    });

    test('fromNewApiJson handles missing fields', () {
      final m = MatchedSubstring.fromNewApiJson({});
      expect(m.offset, 0);
      expect(m.length, 0);
    });
  });

  group('Prediction', () {
    test('fromNewApiJson parses a full suggestion', () {
      final p = Prediction.fromNewApiJson({
        'placeId': 'abc123',
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
        'types': ['locality', 'geocode'],
      });

      expect(p.placeId, 'abc123');
      expect(p.description, 'Paris, France');
      expect(p.matchedSubstrings.length, 1);
      expect(p.matchedSubstrings[0].offset, 0);
      expect(p.matchedSubstrings[0].length, 5);
      expect(p.structuredFormatting!.mainText, 'Paris');
      expect(p.structuredFormatting!.secondaryText, 'France');
      expect(p.types, ['locality', 'geocode']);
    });

    test('fromNewApiJson handles missing optional fields', () {
      final p = Prediction.fromNewApiJson({'placeId': 'x'});
      expect(p.description, isNull);
      expect(p.matchedSubstrings, isEmpty);
      expect(p.structuredFormatting, isNull);
    });
  });

  group('GeocodingResult', () {
    test('fromJson parses a full result', () {
      final r = GeocodingResult.fromJson({
        'place_id': 'place1',
        'formatted_address': '123 Main St',
        'types': ['route'],
        'geometry': {
          'location': {'lat': 10.0, 'lng': 20.0},
        },
        'address_components': [
          {
            'long_name': 'Main St',
            'short_name': 'Main St',
            'types': ['route'],
          }
        ],
      });

      expect(r.placeId, 'place1');
      expect(r.formattedAddress, '123 Main St');
      expect(r.geometry!.location.lat, 10.0);
      expect(r.addressComponents!.length, 1);
    });

    test('fromJson handles missing geometry', () {
      final r = GeocodingResult.fromJson({'place_id': 'p'});
      expect(r.geometry, isNull);
    });
  });

  group('PriceLevel', () {
    test('parsePriceLevel maps all string values', () {
      expect(parsePriceLevel('PRICE_LEVEL_FREE'), PriceLevel.free);
      expect(parsePriceLevel('PRICE_LEVEL_INEXPENSIVE'), PriceLevel.inexpensive);
      expect(parsePriceLevel('PRICE_LEVEL_MODERATE'), PriceLevel.moderate);
      expect(parsePriceLevel('PRICE_LEVEL_EXPENSIVE'), PriceLevel.expensive);
      expect(parsePriceLevel('PRICE_LEVEL_VERY_EXPENSIVE'),
          PriceLevel.veryExpensive);
    });

    test('parsePriceLevel returns unknown for unrecognised value', () {
      expect(parsePriceLevel(null), PriceLevel.unknown);
      expect(parsePriceLevel('PRICE_LEVEL_UNSPECIFIED'), PriceLevel.unknown);
    });
  });

  group('PickResult', () {
    test('fromGeocodingResult uses camera position as authoritative location (B16)', () {
      final geocodingResult = GeocodingResult(
        placeId: 'p1',
        geometry: Geometry(
          location: Location(lat: 0.0, lng: 0.0), // centroid
        ),
        formattedAddress: 'Rural Area, Country',
      );

      final result = PickResult.fromGeocodingResult(
        geocodingResult,
        cameraLat: 10.5,
        cameraLng: 20.5,
      );

      // The geometry must reflect the pin position, not the geocoding centroid.
      expect(result.geometry!.location.lat, 10.5);
      expect(result.geometry!.location.lng, 20.5);
      expect(result.formattedAddress, 'Rural Area, Country');
      expect(result.placeId, 'p1');
    });

    test('fromGeocodingResult falls back to geocoding geometry when no camera position', () {
      final geocodingResult = GeocodingResult(
        placeId: 'p2',
        geometry: Geometry(location: Location(lat: 1.0, lng: 2.0)),
        formattedAddress: 'Place',
      );

      final result = PickResult.fromGeocodingResult(geocodingResult);
      expect(result.geometry!.location.lat, 1.0);
    });

    test('fromPlaceDetailResult maps all fields', () {
      final details = PlaceDetails(
        placeId: 'pd1',
        name: 'Test Place',
        formattedAddress: '1 Test St',
        rating: 4.5,
        website: 'https://example.com',
      );

      final result = PickResult.fromPlaceDetailResult(details);
      expect(result.placeId, 'pd1');
      expect(result.name, 'Test Place');
      expect(result.formattedAddress, '1 Test St');
      expect(result.rating, 4.5);
      expect(result.website, 'https://example.com');
    });
  });
}
