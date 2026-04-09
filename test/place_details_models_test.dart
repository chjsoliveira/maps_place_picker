import 'package:flutter_test/flutter_test.dart';
import 'package:maps_place_picker/src/models/place_details.dart';
import 'package:maps_place_picker/src/models/geometry.dart';

void main() {
  group('OpeningHoursPoint', () {
    test('fromJson parses day, hour, minute', () {
      final point = OpeningHoursPoint.fromJson(
          {'day': 1, 'hour': 9, 'minute': 30});
      expect(point.day, 1);
      expect(point.hour, 9);
      expect(point.minute, 30);
    });

    test('fromJson handles missing fields', () {
      final point = OpeningHoursPoint.fromJson({});
      expect(point.day, isNull);
      expect(point.hour, isNull);
      expect(point.minute, isNull);
    });
  });

  group('OpeningHoursPeriod', () {
    test('fromJson parses open and close', () {
      final period = OpeningHoursPeriod.fromJson({
        'open': {'day': 1, 'hour': 8, 'minute': 0},
        'close': {'day': 1, 'hour': 17, 'minute': 0},
      });

      expect(period.open, isNotNull);
      expect(period.open!.day, 1);
      expect(period.open!.hour, 8);
      expect(period.close, isNotNull);
      expect(period.close!.hour, 17);
    });

    test('fromJson handles missing open', () {
      final period = OpeningHoursPeriod.fromJson({
        'close': {'day': 0, 'hour': 23, 'minute': 59},
      });
      expect(period.open, isNull);
      expect(period.close, isNotNull);
    });

    test('fromJson handles missing close (open 24/7)', () {
      final period = OpeningHoursPeriod.fromJson({
        'open': {'day': 0, 'hour': 0, 'minute': 0},
      });
      expect(period.open, isNotNull);
      expect(period.close, isNull);
    });

    test('fromJson handles empty map', () {
      final period = OpeningHoursPeriod.fromJson({});
      expect(period.open, isNull);
      expect(period.close, isNull);
    });
  });

  group('OpeningHoursDetail', () {
    test('fromJson parses openNow, periods, weekdayText', () {
      final detail = OpeningHoursDetail.fromJson({
        'openNow': true,
        'periods': [
          {
            'open': {'day': 1, 'hour': 9, 'minute': 0},
            'close': {'day': 1, 'hour': 18, 'minute': 0},
          }
        ],
        'weekdayDescriptions': [
          'Monday: 9:00 AM – 6:00 PM',
          'Tuesday: 9:00 AM – 6:00 PM',
        ],
      });

      expect(detail.openNow, isTrue);
      expect(detail.periods, hasLength(1));
      expect(detail.weekdayText, hasLength(2));
      expect(detail.weekdayText![0], contains('Monday'));
    });

    test('fromJson handles openNow=false', () {
      final detail = OpeningHoursDetail.fromJson({'openNow': false});
      expect(detail.openNow, isFalse);
    });

    test('fromJson handles missing optional fields', () {
      final detail = OpeningHoursDetail.fromJson({});
      expect(detail.openNow, isNull);
      expect(detail.periods, isNull);
      expect(detail.weekdayText, isNull);
    });
  });

  group('Photo', () {
    test('fromJson parses name, widthPx, heightPx', () {
      final photo = Photo.fromJson({
        'name': 'places/abc/photos/ref1',
        'widthPx': 1920,
        'heightPx': 1080,
      });

      expect(photo.photoReference, 'places/abc/photos/ref1');
      expect(photo.width, 1920);
      expect(photo.height, 1080);
    });

    test('fromJson handles missing fields', () {
      final photo = Photo.fromJson({});
      expect(photo.photoReference, isNull);
      expect(photo.width, isNull);
      expect(photo.height, isNull);
    });
  });

  group('Review', () {
    test('fromJson parses all fields', () {
      final review = Review.fromJson({
        'authorAttribution': {
          'displayName': 'Alice',
          'photoUri': 'https://example.com/alice.jpg',
          'uri': 'https://example.com/alice',
        },
        'text': {
          'text': 'Great place!',
          'languageCode': 'en',
        },
        'rating': 5,
        'relativePublishTimeDescription': '2 days ago',
        'publishTime': '2024-01-01T00:00:00Z',
      });

      expect(review.authorName, 'Alice');
      expect(review.profilePhotoUrl, 'https://example.com/alice.jpg');
      expect(review.authorUrl, 'https://example.com/alice');
      expect(review.text, 'Great place!');
      expect(review.language, 'en');
      expect(review.rating, 5);
      expect(review.relativeTimeDescription, '2 days ago');
      expect(review.time, '2024-01-01T00:00:00Z');
    });

    test('fromJson handles missing authorAttribution', () {
      final review = Review.fromJson({
        'text': {'text': 'Good'},
        'rating': 3,
      });

      expect(review.authorName, isNull);
      expect(review.profilePhotoUrl, isNull);
      expect(review.text, 'Good');
      expect(review.rating, 3);
    });

    test('fromJson handles empty map', () {
      final review = Review.fromJson({});
      expect(review.authorName, isNull);
      expect(review.text, isNull);
      expect(review.rating, isNull);
    });
  });

  group('PlaceDetails', () {
    test('constructs with minimal fields', () {
      final details = PlaceDetails(placeId: 'pd1');
      expect(details.placeId, 'pd1');
      expect(details.name, isNull);
      expect(details.geometry, isNull);
    });

    test('constructs with all fields', () {
      final geo = Geometry(location: Location(lat: 48.8566, lng: 2.3522));
      final details = PlaceDetails(
        placeId: 'pd2',
        name: 'Paris',
        formattedAddress: 'Paris, France',
        shortFormattedAddress: 'Paris',
        geometry: geo,
        types: ['locality'],
        adrAddress: '<span>Paris</span>',
        formattedPhoneNumber: '+33 1 23 45 67 89',
        internationalPhoneNumber: '+33123456789',
        priceLevel: PriceLevel.moderate,
        rating: 4.5,
        url: 'https://maps.google.com/?cid=123',
        vicinity: 'Paris',
        website: 'https://paris.fr',
      );

      expect(details.name, 'Paris');
      expect(details.geometry!.location.lat, 48.8566);
      expect(details.types, ['locality']);
      expect(details.priceLevel, PriceLevel.moderate);
      expect(details.rating, 4.5);
    });
  });

  group('PriceLevel', () {
    test('parsePriceLevel covers all values', () {
      expect(parsePriceLevel('PRICE_LEVEL_FREE'), PriceLevel.free);
      expect(
          parsePriceLevel('PRICE_LEVEL_INEXPENSIVE'), PriceLevel.inexpensive);
      expect(parsePriceLevel('PRICE_LEVEL_MODERATE'), PriceLevel.moderate);
      expect(parsePriceLevel('PRICE_LEVEL_EXPENSIVE'), PriceLevel.expensive);
      expect(parsePriceLevel('PRICE_LEVEL_VERY_EXPENSIVE'),
          PriceLevel.veryExpensive);
    });

    test('parsePriceLevel returns unknown for null', () {
      expect(parsePriceLevel(null), PriceLevel.unknown);
    });

    test('parsePriceLevel returns unknown for unspecified', () {
      expect(parsePriceLevel('PRICE_LEVEL_UNSPECIFIED'), PriceLevel.unknown);
    });

    test('parsePriceLevel returns unknown for unknown string', () {
      expect(parsePriceLevel('RANDOM'), PriceLevel.unknown);
    });
  });
}
