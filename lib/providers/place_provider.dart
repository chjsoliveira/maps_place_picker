import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_place_picker/src/models/pick_result.dart';
import 'package:maps_place_picker/src/place_picker.dart';
import 'package:maps_place_picker/src/services/geocoding_service.dart';
import 'package:maps_place_picker/src/services/places_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

/// Shared state provider for [PlacePicker].
///
/// Holds the Google Maps Places/Geocoding service instances, the current
/// device position, camera state, selected place, and UI state flags.
/// Consumed via [Provider] throughout the widget tree.
class PlaceProvider extends ChangeNotifier {
  /// Creates a [PlaceProvider] and initialises the underlying Google Maps
  /// web-service clients.
  ///
  /// [apiKey] is the Google Maps API key.
  /// [proxyBaseUrl] is an optional proxy base URL (the key is not needed when
  /// the proxy sets it).
  /// [httpClient] is an optional custom HTTP client for the web-service calls.
  /// [apiHeaders] are extra request headers forwarded to every API call.
  PlaceProvider(
    String apiKey,
    String? proxyBaseUrl,
    Client? httpClient,
    Map<String, dynamic> apiHeaders,
  ) {
    places = PlacesService(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders.cast<String, String>(),
    );
    geocoding = GeocodingService(
      apiKey: apiKey,
      baseUrl: proxyBaseUrl,
      httpClient: httpClient,
      apiHeaders: apiHeaders.cast<String, String>(),
    );
  }

  /// Returns the nearest [PlaceProvider] ancestor from [context].
  static PlaceProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<PlaceProvider>(context, listen: listen);

  /// The Places API (New) service used for autocomplete and place-detail
  /// lookups.
  late PlacesService places;

  /// The Geocoding API service used for reverse-geocoding the camera position.
  late GeocodingService geocoding;

  /// Session token used to group autocomplete queries and detail fetches into
  /// a single billable session.
  String? sessionToken;

  /// Whether the "my location" button is currently in its cooldown period.
  bool isOnUpdateLocationCooldown = false;

  /// Desired accuracy passed to [Geolocator] when fetching the current
  /// device position.
  LocationAccuracy? desiredAccuracy;

  /// `true` while an autocomplete-initiated search is in progress, which
  /// prevents a redundant camera-move search from firing.
  bool isAutoCompleteSearching = false;

  /// Resolves the device's current GPS position and stores it in
  /// [currentPosition].
  ///
  /// When [gracefully] is `true` any permission or service error is silently
  /// swallowed instead of propagating as a [Future.error].
  Future<void> updateCurrentLocation({bool gracefully = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      if (gracefully) {
        // Or you can swallow the issue and respect the user's privacy
        return;
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        if (gracefully) {
          // Or you can swallow the issue and respect the user's privacy
          return;
        }
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      if (gracefully) {
        // Or you can swallow the issue and respect the user's privacy
        return;
      }
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: desiredAccuracy ?? LocationAccuracy.best,
      ),
    );
  }

  Position? _currentPosition;

  /// The most recently resolved device [Position], or `null` if location has
  /// not been fetched yet or permission was denied.
  Position? get currentPosition => _currentPosition;

  /// Updates [currentPosition] and notifies listeners.
  set currentPosition(Position? newPosition) {
    _currentPosition = newPosition;
    notifyListeners();
  }

  Timer? _debounceTimer;

  /// Active debounce [Timer] for camera-move searches, or `null`.
  Timer? get debounceTimer => _debounceTimer;

  /// Replaces the active debounce timer and notifies listeners.
  set debounceTimer(Timer? timer) {
    _debounceTimer = timer;
    notifyListeners();
  }

  CameraPosition? _previousCameraPosition;

  /// The camera position captured just before the most recent camera movement
  /// started. Used to detect zoom-only changes.
  CameraPosition? get prevCameraPosition => _previousCameraPosition;

  /// Stores [prePosition] as the previous camera position without notifying
  /// listeners (called in the hot camera-move path).
  void setPrevCameraPosition(CameraPosition? prePosition) {
    _previousCameraPosition = prePosition;
  }

  CameraPosition? _currentCameraPosition;

  /// The current camera position as reported by the [GoogleMap] widget.
  CameraPosition? get cameraPosition => _currentCameraPosition;

  /// Stores [newPosition] as the current camera position without notifying
  /// listeners (called in the hot camera-move path).
  void setCameraPosition(CameraPosition? newPosition) {
    _currentCameraPosition = newPosition;
  }

  PickResult? _selectedPlace;

  /// The place that is currently selected / shown in the floating card.
  PickResult? get selectedPlace => _selectedPlace;

  /// Updates [selectedPlace] and notifies listeners.
  set selectedPlace(PickResult? result) {
    _selectedPlace = result;
    notifyListeners();
  }

  SearchingState _placeSearchingState = SearchingState.idle;

  /// Whether a place search is currently in progress.
  SearchingState get placeSearchingState => _placeSearchingState;

  /// Updates [placeSearchingState] and notifies listeners.
  set placeSearchingState(SearchingState newState) {
    _placeSearchingState = newState;
    notifyListeners();
  }

  GoogleMapController? _mapController;

  /// Controller for the underlying [GoogleMap] widget.
  GoogleMapController? get mapController => _mapController;

  /// Updates [mapController] and notifies listeners.
  set mapController(GoogleMapController? controller) {
    _mapController = controller;
    notifyListeners();
  }

  PinState _pinState = PinState.preparing;

  /// Current visual state of the map pin.
  PinState get pinState => _pinState;

  /// Updates [pinState] and notifies listeners.
  set pinState(PinState newState) {
    _pinState = newState;
    notifyListeners();
  }

  bool _isSeachBarFocused = false;

  /// Whether the search bar currently has keyboard focus.
  bool get isSearchBarFocused => _isSeachBarFocused;

  /// Updates [isSearchBarFocused] and notifies listeners.
  set isSearchBarFocused(bool focused) {
    _isSeachBarFocused = focused;
    notifyListeners();
  }

  MapType _mapType = MapType.normal;

  /// The currently active [MapType].
  MapType get mapType => _mapType;

  /// Sets [mapType] directly. Pass `notify: true` to also call
  /// [notifyListeners].
  void setMapType(MapType mapType, {bool notify = false}) {
    _mapType = mapType;
    if (notify) notifyListeners();
  }

  /// Advances [mapType] to the next value in [MapType.values], skipping
  /// [MapType.none], and notifies listeners.
  void switchMapType() {
    _mapType = MapType.values[(_mapType.index + 1) % MapType.values.length];
    if (_mapType == MapType.none) _mapType = MapType.normal;
    notifyListeners();
  }

  /// `true` when the initial search triggered by [selectInitialPosition] is
  /// still pending (waiting for the first [onCameraIdle] after map creation).
  bool pendingInitialSearch = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
