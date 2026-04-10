import 'package:maps_place_picker/src/models/address_component.dart';
import 'package:maps_place_picker/src/models/geometry.dart';

/// Price level of a place, as returned by the Places API (New).
enum PriceLevel {
  /// The place is free of charge.
  free,

  /// The place has inexpensive pricing.
  inexpensive,

  /// The place has moderate pricing.
  moderate,

  /// The place has expensive pricing.
  expensive,

  /// The place has very expensive pricing.
  veryExpensive,

  /// The price level is not available or not applicable.
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
  /// Creates an [OpeningHoursPeriod] with optional [open] and [close] points.
  const OpeningHoursPeriod({this.open, this.close});

  /// The time at which the period starts (opening time).
  final OpeningHoursPoint? open;

  /// The time at which the period ends (closing time).
  final OpeningHoursPoint? close;

  /// Parses an [OpeningHoursPeriod] from the Places API JSON format.
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
  /// Creates an [OpeningHoursPoint] with optional [day], [hour], and [minute].
  const OpeningHoursPoint({this.day, this.hour, this.minute});

  /// Day of week: 0 = Sunday … 6 = Saturday.
  final int? day;

  /// Hour of the day in 24-hour format (0–23).
  final int? hour;

  /// Minute of the hour (0–59).
  final int? minute;

  /// Parses an [OpeningHoursPoint] from the Places API JSON format.
  factory OpeningHoursPoint.fromJson(Map<String, dynamic> json) =>
      OpeningHoursPoint(
        day: json['day'] as int?,
        hour: json['hour'] as int?,
        minute: json['minute'] as int?,
      );
}

/// Opening hours information for a place.
class OpeningHoursDetail {
  /// Creates an [OpeningHoursDetail] with optional fields.
  const OpeningHoursDetail({this.openNow, this.periods, this.weekdayText});

  /// Whether the place is currently open.
  final bool? openNow;

  /// List of opening periods for each day of the week.
  final List<OpeningHoursPeriod>? periods;

  /// Human-readable weekday opening hours (one entry per day).
  final List<String>? weekdayText;

  /// Parses an [OpeningHoursDetail] from the Places API (New) JSON format.
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
  /// Creates a [Photo] with optional [photoReference], [width], and [height].
  const Photo({this.photoReference, this.width, this.height});

  /// The Places API (New) photo resource name used to fetch the photo.
  final String? photoReference;

  /// Width of the photo in pixels.
  final int? width;

  /// Height of the photo in pixels.
  final int? height;

  /// Parses a [Photo] from the Places API (New) JSON format.
  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        photoReference: json['name'] as String?,
        width: json['widthPx'] as int?,
        height: json['heightPx'] as int?,
      );
}

/// A user-contributed review of a place.
class Review {
  /// Creates a [Review] with optional fields.
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

  /// Display name of the reviewer.
  final String? authorName;

  /// URL of the reviewer's profile photo.
  final String? profilePhotoUrl;

  /// Human-readable description of the review's age (e.g. "a month ago").
  final String? relativeTimeDescription;

  /// Numeric rating given by the reviewer (0–5).
  final num? rating;

  /// Text content of the review.
  final String? text;

  /// ISO 8601 timestamp of when the review was published.
  final String? time;

  /// URL of the reviewer's Google Maps profile.
  final String? authorUrl;

  /// BCP-47 language code of the review text.
  final String? language;

  /// Parses a [Review] from the Places API (New) JSON format.
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
  /// Creates a [PlaceDetails] with the given fields.
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

  /// The unique Place ID returned by the Places API.
  final String? placeId;

  /// Human-readable name of the place.
  final String? name;

  /// Full human-readable address of the place.
  final String? formattedAddress;

  /// Shorter formatted address, used as a [vicinity] substitute.
  final String? shortFormattedAddress;

  /// Geographic location and viewport for the place.
  final Geometry? geometry;

  /// List of place-type strings (e.g. `["restaurant", "food"]`).
  final List<String>? types;

  /// Structured address components (street, city, country, etc.).
  final List<AddressComponent>? addressComponents;

  /// Address in [adr microformat](http://microformats.org/wiki/adr).
  final String? adrAddress;

  /// Local phone number in national format.
  final String? formattedPhoneNumber;

  /// Phone number in international format.
  final String? internationalPhoneNumber;

  /// Price level of the place.
  final PriceLevel? priceLevel;

  /// Average user rating (0.0–5.0).
  final num? rating;

  /// Maps to the `googleMapsUri` field in the Places API (New).
  final String? url;

  /// Short formatted address used as a vicinity substitute.
  final String? vicinity;

  /// Official website of the place.
  final String? website;

  /// Opening hours information for the place.
  final OpeningHoursDetail? openingHours;

  /// Photos associated with the place.
  final List<Photo>? photos;

  /// User-contributed reviews for the place.
  final List<Review>? reviews;
}
