import 'package:maps_place_picker/src/models/address_component.dart';
import 'package:maps_place_picker/src/models/geometry.dart';

/// Price level of a place, as returned by the Places API (New).
enum PriceLevel {
  free,
  inexpensive,
  moderate,
  expensive,
  veryExpensive,
  unknown,
}

/// Parses the Places API (New) string price level into a [PriceLevel].
PriceLevel parsePriceLevel(String? value) {
  switch (value) {
    case 'PRICE_LEVEL_FREE':
      return PriceLevel.free;
    case 'PRICE_LEVEL_INEXPENSIVE':
      return PriceLevel.inexpensive;
    case 'PRICE_LEVEL_MODERATE':
      return PriceLevel.moderate;
    case 'PRICE_LEVEL_EXPENSIVE':
      return PriceLevel.expensive;
    case 'PRICE_LEVEL_VERY_EXPENSIVE':
      return PriceLevel.veryExpensive;
    default:
      return PriceLevel.unknown;
  }
}

/// Opening hours period for a single day.
class OpeningHoursPeriod {
  const OpeningHoursPeriod({this.open, this.close});

  final OpeningHoursPoint? open;
  final OpeningHoursPoint? close;

  factory OpeningHoursPeriod.fromJson(Map<String, dynamic> json) =>
      OpeningHoursPeriod(
        open: json['open'] != null
            ? OpeningHoursPoint.fromJson(json['open'] as Map<String, dynamic>)
            : null,
        close: json['close'] != null
            ? OpeningHoursPoint.fromJson(json['close'] as Map<String, dynamic>)
            : null,
      );
}

/// A day-of-week and time-of-day point in an opening hours period.
class OpeningHoursPoint {
  const OpeningHoursPoint({this.day, this.hour, this.minute});

  /// Day of week: 0 = Sunday … 6 = Saturday.
  final int? day;
  final int? hour;
  final int? minute;

  factory OpeningHoursPoint.fromJson(Map<String, dynamic> json) =>
      OpeningHoursPoint(
        day: json['day'] as int?,
        hour: json['hour'] as int?,
        minute: json['minute'] as int?,
      );
}

/// Opening hours information for a place.
class OpeningHoursDetail {
  const OpeningHoursDetail({this.openNow, this.periods, this.weekdayText});

  final bool? openNow;
  final List<OpeningHoursPeriod>? periods;

  /// Human-readable weekday opening hours (one entry per day).
  final List<String>? weekdayText;

  factory OpeningHoursDetail.fromJson(Map<String, dynamic> json) =>
      OpeningHoursDetail(
        openNow: json['openNow'] as bool?,
        periods: (json['periods'] as List<dynamic>?)
            ?.map((e) =>
                OpeningHoursPeriod.fromJson(e as Map<String, dynamic>))
            .toList(),
        weekdayText: (json['weekdayDescriptions'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );
}

/// Photo associated with a place.
///
/// [photoReference] holds the Places API (New) photo resource name
/// (e.g. `places/<id>/photos/<photoRef>`) which can be used to fetch the
/// photo via the Photo Media API endpoint.
class Photo {
  const Photo({this.photoReference, this.width, this.height});

  final String? photoReference;
  final int? width;
  final int? height;

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        photoReference: json['name'] as String?,
        width: json['widthPx'] as int?,
        height: json['heightPx'] as int?,
      );
}

/// A user-contributed review of a place.
class Review {
  const Review({
    this.authorName,
    this.profilePhotoUrl,
    this.relativeTimeDescription,
    this.rating,
    this.text,
    this.time,
    this.authorUrl,
    this.language,
  });

  final String? authorName;
  final String? profilePhotoUrl;
  final String? relativeTimeDescription;
  final num? rating;
  final String? text;
  final String? time;
  final String? authorUrl;
  final String? language;

  factory Review.fromJson(Map<String, dynamic> json) {
    final author =
        json['authorAttribution'] as Map<String, dynamic>?;
    final textObj = json['text'] as Map<String, dynamic>?;
    return Review(
      authorName: author?['displayName'] as String?,
      profilePhotoUrl: author?['photoUri'] as String?,
      authorUrl: author?['uri'] as String?,
      relativeTimeDescription:
          json['relativePublishTimeDescription'] as String?,
      rating: json['rating'] as num?,
      text: textObj?['text'] as String?,
      language: textObj?['languageCode'] as String?,
      time: json['publishTime'] as String?,
    );
  }
}

/// Detailed information about a place as returned by the Places API (New).
class PlaceDetails {
  PlaceDetails({
    this.placeId,
    this.name,
    this.formattedAddress,
    this.shortFormattedAddress,
    this.geometry,
    this.types,
    this.addressComponents,
    this.adrAddress,
    this.formattedPhoneNumber,
    this.internationalPhoneNumber,
    this.priceLevel,
    this.rating,
    this.url,
    this.vicinity,
    this.website,
    this.openingHours,
    this.photos,
    this.reviews,
  });

  final String? placeId;
  final String? name;
  final String? formattedAddress;
  final String? shortFormattedAddress;
  final Geometry? geometry;
  final List<String>? types;
  final List<AddressComponent>? addressComponents;
  final String? adrAddress;
  final String? formattedPhoneNumber;
  final String? internationalPhoneNumber;
  final PriceLevel? priceLevel;
  final num? rating;

  /// Maps to the `googleMapsUri` field in the Places API (New).
  final String? url;

  /// Short formatted address used as a vicinity substitute.
  final String? vicinity;
  final String? website;
  final OpeningHoursDetail? openingHours;
  final List<Photo>? photos;
  final List<Review>? reviews;
}
