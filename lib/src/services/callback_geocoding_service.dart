import 'package:maps_place_picker/src/models/geocoding_result.dart';
import 'package:maps_place_picker/src/services/geocoding_service.dart';

/// Reverse-geocodes a coordinate without prescribing a transport or provider.
typedef ReverseGeocodeFetcher = Future<GeocodingResult?> Function(
  double latitude,
  double longitude, {
  String? language,
});

/// Forward-geocodes an address without prescribing a transport or provider.
typedef ForwardGeocodeFetcher = Future<List<GeocodingResult>> Function(
  String address, {
  String? language,
});

/// A geocoding data source backed entirely by host-app callbacks.
class CallbackGeocodingService implements GeocodingDataSource {
  /// Creates a callback-backed data source.
  const CallbackGeocodingService({
    required this.reverseGeocodeFetcher,
    this.forwardGeocodeFetcher,
  });

  /// Callback used for reverse geocoding.
  final ReverseGeocodeFetcher reverseGeocodeFetcher;

  /// Optional callback used for forward geocoding.
  final ForwardGeocodeFetcher? forwardGeocodeFetcher;

  @override
  Future<GeocodingResponse> searchByLocation(
    double latitude,
    double longitude, {
    String? language,
  }) async {
    try {
      final result = await reverseGeocodeFetcher(
        latitude,
        longitude,
        language: language,
      );
      return GeocodingResponse(
        status: result == null ? 'ZERO_RESULTS' : 'OK',
        results: result == null ? const [] : [result],
      );
    } catch (error) {
      return GeocodingResponse(
        status: 'NETWORK_ERROR',
        results: const [],
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<GeocodingResponse> searchByAddress(
    String address, {
    String? language,
  }) async {
    final fetcher = forwardGeocodeFetcher;
    if (fetcher == null) {
      return const GeocodingResponse(status: 'ZERO_RESULTS', results: []);
    }
    try {
      final results = await fetcher(address, language: language);
      return GeocodingResponse(
        status: results.isEmpty ? 'ZERO_RESULTS' : 'OK',
        results: results,
      );
    } catch (error) {
      return GeocodingResponse(
        status: 'NETWORK_ERROR',
        results: const [],
        errorMessage: error.toString(),
      );
    }
  }
}
