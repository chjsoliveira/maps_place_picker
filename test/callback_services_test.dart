import 'package:flutter_test/flutter_test.dart';
import 'package:maps_place_picker/maps_place_picker.dart';

void main() {
  test('callback Places source delegates search and details', () async {
    final service = CallbackPlacesService(
      searchFetcher: (input, {
        sessionToken,
        latitude,
        longitude,
        radius,
        language,
        types,
        components,
        strictbounds = false,
        region,
        offset,
      }) async =>
          [Prediction(placeId: 'result', description: input)],
      detailsFetcher: (placeId, {sessionToken, language}) async => PlaceDetails(
        placeId: placeId,
        formattedAddress: 'Address',
      ),
    );

    final search = await service.autocomplete('Query');
    final details = await service.getDetailsByPlaceId('result');

    expect(search.status, 'OK');
    expect(search.predictions.single.description, 'Query');
    expect(details.status, 'OK');
    expect(details.result?.placeId, 'result');
  });

  test('callback services map exceptions to network errors', () async {
    final places = CallbackPlacesService(
      searchFetcher: (input, {
        sessionToken,
        latitude,
        longitude,
        radius,
        language,
        types,
        components,
        strictbounds = false,
        region,
        offset,
      }) async =>
          throw Exception('places failed'),
      detailsFetcher: (placeId, {sessionToken, language}) async => null,
    );
    final geocoding = CallbackGeocodingService(
      reverseGeocodeFetcher: (latitude, longitude, {language}) async =>
          throw Exception('geocoding failed'),
    );

    expect((await places.autocomplete('Query')).status, 'NETWORK_ERROR');
    expect((await geocoding.searchByLocation(1, 2)).status, 'NETWORK_ERROR');
  });

  test('distance-ranked callback receives the picker session token', () async {
    String? capturedSessionToken;
    final service = CallbackPlacesService(
      searchFetcher: (input, {
        sessionToken,
        latitude,
        longitude,
        radius,
        language,
        types,
        components,
        strictbounds = false,
        region,
        offset,
      }) async {
        capturedSessionToken = sessionToken;
        return const [];
      },
      detailsFetcher: (placeId, {sessionToken, language}) async => null,
    );

    await service.searchTextRankedByDistance(
      'Query',
      sessionToken: 'picker-session',
      latitude: 1,
      longitude: 2,
    );

    expect(capturedSessionToken, 'picker-session');
  });

  test('callback geocoding supports reverse and optional forward lookup',
      () async {
    const result = GeocodingResult(
      placeId: 'place',
      formattedAddress: 'Address',
      geometry: Geometry(location: Location(lat: 1, lng: 2)),
    );
    final reverseOnly = CallbackGeocodingService(
      reverseGeocodeFetcher: (latitude, longitude, {language}) async => result,
    );
    final complete = CallbackGeocodingService(
      reverseGeocodeFetcher: (latitude, longitude, {language}) async => result,
      forwardGeocodeFetcher: (address, {language}) async => [result],
    );

    expect((await reverseOnly.searchByLocation(1, 2)).status, 'OK');
    expect((await reverseOnly.searchByAddress('Address')).status,
        'ZERO_RESULTS');
    expect((await complete.searchByAddress('Address')).results, [result]);
  });
}
