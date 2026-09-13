import 'package:maps_place_picker/src/models/component.dart';
import 'package:maps_place_picker/src/models/place_details.dart';
import 'package:maps_place_picker/src/models/prediction.dart';
import 'package:maps_place_picker/src/services/places_service.dart';

/// Fetches place predictions without prescribing a transport or provider.
typedef PlacesSearchFetcher = Future<List<Prediction>> Function(
  String input, {
  String? sessionToken,
  double? latitude,
  double? longitude,
  num? radius,
  String? language,
  List<String>? types,
  List<Component>? components,
  bool strictbounds,
  String? region,
  num? offset,
});

/// Fetches full details for [placeId].
typedef PlaceDetailsFetcher = Future<PlaceDetails?> Function(
  String placeId, {
  String? sessionToken,
  String? language,
});

/// A Places data source backed entirely by host-app callbacks.
class CallbackPlacesService implements PlacesDataSource {
  /// Creates a callback-backed data source.
  const CallbackPlacesService({
    required this.searchFetcher,
    required this.detailsFetcher,
  });

  /// Callback used for autocomplete and distance-ranked search.
  final PlacesSearchFetcher searchFetcher;

  /// Callback used for place details.
  final PlaceDetailsFetcher detailsFetcher;

  @override
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
      final predictions = await searchFetcher(
        input,
        sessionToken: sessionToken,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        language: language,
        types: types,
        components: components,
        strictbounds: strictbounds,
        region: region,
        offset: offset,
      );
      return PlacesAutocompleteResponse(status: 'OK', predictions: predictions);
    } catch (error) {
      return PlacesAutocompleteResponse(
        status: 'NETWORK_ERROR',
        predictions: const [],
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<PlacesAutocompleteResponse> searchTextRankedByDistance(
    String textQuery, {
    String? sessionToken,
    required double latitude,
    required double longitude,
    num? radius,
    String? language,
    List<String>? types,
    bool strictbounds = false,
    String? region,
  }) async {
    try {
      final predictions = await searchFetcher(
        textQuery,
        sessionToken: sessionToken,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        language: language,
        types: types,
        strictbounds: strictbounds,
        region: region,
      );
      return PlacesAutocompleteResponse(status: 'OK', predictions: predictions);
    } catch (error) {
      return PlacesAutocompleteResponse(
        status: 'NETWORK_ERROR',
        predictions: const [],
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<PlacesDetailsResponse> getDetailsByPlaceId(
    String placeId, {
    String? sessionToken,
    String? language,
  }) async {
    try {
      final result = await detailsFetcher(
        placeId,
        sessionToken: sessionToken,
        language: language,
      );
      return result == null
          ? const PlacesDetailsResponse(status: 'ZERO_RESULTS')
          : PlacesDetailsResponse(status: 'OK', result: result);
    } catch (error) {
      return PlacesDetailsResponse(
        status: 'NETWORK_ERROR',
        errorMessage: error.toString(),
      );
    }
  }
}
