import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_place_picker/maps_place_picker.dart';
import 'package:maps_place_picker/providers/place_provider.dart';
import 'package:maps_place_picker/src/autocomplete_search.dart';
import 'package:maps_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:maps_place_picker/src/google_map_place_picker.dart';
import 'package:maps_place_picker/src/models/prediction.dart';
import 'package:maps_place_picker/src/services/places_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Signature for a builder that creates an intro modal overlay.
///
/// [context] is the current [BuildContext]. [close] is a callback that hides
/// the modal when invoked.
typedef IntroModalWidgetBuilder = Widget Function(
  BuildContext context,
  Function? close,
);

/// Visual state of the draggable map pin.
enum PinState {
  /// The pin is being prepared before the map is fully ready.
  preparing,

  /// The pin is stationary and no camera movement is in progress.
  idle,

  /// The user is actively dragging the pin / moving the camera.
  dragging,
}

/// Whether a place search is currently in flight.
enum SearchingState {
  /// No search is in progress.
  idle,

  /// A search request has been sent and a response is awaited.
  searching,
}

/// A full-screen widget that lets users search for and select a location.
///
/// Renders a [GoogleMap] with an autocomplete search bar, a draggable pin, and
/// a floating card that shows the selected place. The selected result is
/// returned via [onPlacePicked].
///
/// Uses the **Places API (New)** for autocomplete and place details and the
/// **Geocoding API** for reverse-geocoding the camera position.
class PlacePicker extends StatefulWidget {
  /// Creates a [PlacePicker].
  ///
  /// [apiKey] and [initialPosition] are required. All other parameters are
  /// optional and have sensible defaults.
  const PlacePicker({
    super.key,
    required this.apiKey,
    this.onPlacePicked,
    required this.initialPosition,
    this.useCurrentLocation,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.onMapCreated,
    this.hintText,
    this.searchingText,
    this.selectText,
    this.outsideOfPickAreaText,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.proxyBaseUrl,
    this.httpClient,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.introModalWidgetBuilder,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 750,
    this.initialMapType = MapType.normal,
    this.enableMapTypeButton = true,
    this.enableMyLocationButton = true,
    this.myLocationButtonCooldown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictbounds,
    this.region,
    this.pickArea,
    this.selectInitialPosition = false,
    this.resizeToAvoidBottomInset = true,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceSearchOnZoomChanged = false,
    this.automaticallyImplyAppBarLeading = true,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
    this.ignoreLocationPermissionErrors = false,
    this.onTapBack,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onMapTypeChanged,
    this.zoomGesturesEnabled = true,
    this.zoomControlsEnabled = false,
    this.showSearchBar = true,
    this.selectedPlaceButtonColor,
    this.initialZoom = 15.0,
    this.initialTilt = 0.0,
    this.initialBearing = 0.0,
    this.voiceSearchEnabled = false,
    this.onVoiceSearchTapped,
    this.markers,
    this.polylines,
    this.polygons,
  });

  /// Google Maps API key used for Places and Geocoding requests.
  final String apiKey;

  /// The initial camera position shown when the picker opens.
  final LatLng initialPosition;

  /// Whether to move the camera to the device's current location on open.
  final bool? useCurrentLocation;

  /// Desired GPS accuracy when fetching the current location.
  final LocationAccuracy desiredLocationAccuracy;

  /// Hint text shown in the empty search field.
  final String? hintText;

  /// Text shown in the search bar while an autocomplete request is in flight.
  final String? searchingText;

  /// Label for the "Select here" confirmation button.
  final String? selectText;

  /// Text shown when the selected pin is outside the [pickArea].
  final String? outsideOfPickAreaText;

  /// Called with the status string when an autocomplete request fails.
  final ValueChanged<String>? onAutoCompleteFailed;

  /// Called with the status string when a geocoding request fails.
  final ValueChanged<String>? onGeocodingSearchFailed;

  /// Debounce delay in milliseconds for autocomplete requests. Defaults to 500.
  final int autoCompleteDebounceInMilliseconds;

  /// Debounce delay in milliseconds for camera-move searches. Defaults to 750.
  final int cameraMoveDebounceInMilliseconds;

  /// The [MapType] shown when the picker first opens.
  final MapType initialMapType;

  /// Whether to show the map-type toggle button.
  final bool enableMapTypeButton;

  /// Whether to show the "my location" button.
  final bool enableMyLocationButton;

  /// Cooldown in seconds for the "my location" button after it is tapped.
  final int myLocationButtonCooldown;

  /// Whether to trigger a reverse-geocode search when the camera stops moving.
  final bool usePinPointingSearch;

  /// Whether to fetch full place details via the Places API after a pin pick.
  final bool usePlaceDetailSearch;

  /// Character offset passed to the autocomplete API.
  final num? autocompleteOffset;

  /// Search radius in metres passed to the autocomplete API.
  final num? autocompleteRadius;

  /// BCP-47 language code for localising autocomplete results.
  final String? autocompleteLanguage;

  /// Place-type filters for the autocomplete request.
  final List<String>? autocompleteTypes;

  /// Country (or other component) filters for the autocomplete request.
  final List<Component>? autocompleteComponents;

  /// When `true`, restricts autocomplete results to the [autocompleteRadius]
  /// circle instead of merely biasing them.
  final bool? strictbounds;

  /// CLDR two-character region code used to bias autocomplete results.
  final String? region;

  /// If set the picker can only pick addresses in the given circle area.
  /// The section will be highlighted.
  final CircleArea? pickArea;

  /// If true the [body] and the scaffold's floating widgets should size
  /// themselves to avoid the onscreen keyboard whose height is defined by the
  /// ambient [MediaQuery]'s [MediaQueryData.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomInset;

  /// Whether to trigger a search on the initial camera position immediately
  /// after the map is created.
  final bool selectInitialPosition;

  /// By using default setting of Place Picker, it will result result when user hits the select here button.
  ///
  /// If you managed to use your own [selectedPlaceWidgetBuilder], then this WILL NOT be invoked, and you need use data which is
  /// being sent with [selectedPlaceWidgetBuilder].
  final ValueChanged<PickResult>? onPlacePicked;

  /// optional - builds selected place's UI
  ///
  /// It is provided by default if you leave it as a null.
  /// INPORTANT: If this is non-null, [onPlacePicked] will not be invoked, as there will be no default 'Select here' button.
  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;

  /// optional - builds customized pin widget which indicates current pointing position.
  ///
  /// It is provided by default if you leave it as a null.
  final PinBuilder? pinBuilder;

  /// optional - builds customized introduction panel.
  ///
  /// None is provided / the map is instantly accessible if you leave it as a null.
  final IntroModalWidgetBuilder? introModalWidgetBuilder;

  /// optional - sets 'proxy' value in google_maps_webservice
  ///
  /// In case of using a proxy the baseUrl can be set.
  /// The apiKey is not required in case the proxy sets it.
  /// (Not storing the apiKey in the app is good practice)
  final String? proxyBaseUrl;

  /// optional - set 'client' value in google_maps_webservice
  ///
  /// In case of using a proxy url that requires authentication
  /// or custom configuration.
  ///
  /// **Security:** the client must use HTTPS to ensure all API communication
  /// is encrypted. Never pass a client configured for plain HTTP.
  final BaseClient? httpClient;

  /// Initial value of autocomplete search
  final String? initialSearchString;

  /// Whether to search for the initial value or not
  final bool searchForInitialValue;

  /// Allow searching place when zoom has changed. By default searching is disabled when zoom has changed in order to prevent unwilling API usage.
  final bool forceSearchOnZoomChanged;

  /// Whether to display appbar backbutton. Defaults to true.
  final bool automaticallyImplyAppBarLeading;

  /// Will perform an autocomplete search, if set to true. Note that setting
  /// this to true, while providing a smoother UX experience, may cause
  /// additional unnecessary queries to the Places API.
  ///
  /// Defaults to false.
  final bool autocompleteOnTrailingWhitespace;

  /// Whether to hide place details when dragging pin. Defaults to true.
  final bool hidePlaceDetailsWhenDraggingPin;

  /// Whether to ignore location permission errors. Defaults to false.
  /// If this is set to `true` the UI will be blocked.
  final bool ignoreLocationPermissionErrors;

  // Raised when clicking on the back arrow.
  // This will not listen for the system back button on Android devices.
  // If this is not set, but the back button is visible through automaticallyImplyLeading,
  // the Navigator will try to pop instead.
  final VoidCallback? onTapBack;

  /// GoogleMap pass-through events:

  /// Callback method for when the map is ready to be used.
  ///
  /// Used to receive a [GoogleMapController] for this [GoogleMap].
  final MapCreatedCallback? onMapCreated;

  /// Called when the camera starts moving.
  ///
  /// This can be initiated by the following:
  /// 1. Non-gesture animation initiated in response to user actions.
  ///    For example: zoom buttons, my location button, or marker clicks.
  /// 2. Programmatically initiated animation.
  /// 3. Camera motion initiated in response to user gestures on the map.
  ///    For example: pan, tilt, pinch to zoom, or rotate.
  final Function(PlaceProvider)? onCameraMoveStarted;

  /// Called repeatedly as the camera continues to move after an
  /// onCameraMoveStarted call.
  ///
  /// This may be called as often as once every frame and should
  /// not perform expensive operations.
  final CameraPositionCallback? onCameraMove;

  /// Called when camera movement has ended, there are no pending
  /// animations and the user has stopped interacting with the map.
  final Function(PlaceProvider)? onCameraIdle;

  /// Called when the map type has been changed.
  final Function(MapType)? onMapTypeChanged;

  /// Toggle on & off zoom gestures
  final bool zoomGesturesEnabled;

  /// Allow user to make visible the zoom button
  final bool zoomControlsEnabled;

  /// Whether to show the search bar. Defaults to `true`.
  ///
  /// When `false`, the autocomplete search field is hidden but the back button
  /// in the AppBar is still shown. This is useful when you want to provide
  /// your own search UI or use the picker in pure pin-drag mode.
  final bool showSearchBar;

  /// Optional override colour for the "Select here" button when the selected
  /// location is inside the [pickArea]. Defaults to [Colors.lightGreen].
  final Color? selectedPlaceButtonColor;

  /// Initial camera zoom level. Defaults to `15.0`.
  final double initialZoom;

  /// Initial camera tilt in degrees. Defaults to `0.0`.
  final double initialTilt;

  /// Initial camera bearing in degrees clockwise from north. Defaults to `0.0`.
  final double initialBearing;

  /// Whether to show a microphone button for voice input. Defaults to `false`.
  ///
  /// When `true`, a mic icon appears in the search bar. Tapping it calls
  /// [onVoiceSearchTapped]. The consumer handles speech recognition and feeds
  /// results back via [SearchBarController.setText].
  final bool voiceSearchEnabled;

  /// Called when the microphone button is tapped.
  ///
  /// Only invoked when [voiceSearchEnabled] is `true`.
  final VoidCallback? onVoiceSearchTapped;

  /// Optional set of [Marker]s to display on the map in addition to the
  /// built-in draggable pin.
  final Set<Marker>? markers;

  /// Optional set of [Polyline]s to overlay on the map.
  final Set<Polyline>? polylines;

  /// Optional set of [Polygon]s to overlay on the map.
  final Set<Polygon>? polygons;

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  GlobalKey appBarKey = GlobalKey();
  late final Future<PlaceProvider> _futureProvider;
  PlaceProvider? provider;
  SearchBarController searchBarController = SearchBarController();
  bool showIntroModal = true;

  @override
  void initState() {
    super.initState();

    _futureProvider = _initPlaceProvider();
  }

  @override
  void dispose() {
    searchBarController.dispose();

    super.dispose();
  }

  Future<PlaceProvider> _initPlaceProvider() async {
    final headers = await const GoogleApiHeaders().getHeaders();
    final provider = PlaceProvider(
      widget.apiKey,
      widget.proxyBaseUrl,
      widget.httpClient,
      headers,
    );
    provider.sessionToken = const Uuid().v4();
    provider.desiredAccuracy = widget.desiredLocationAccuracy;
    provider.setMapType(widget.initialMapType);
    if (widget.useCurrentLocation != null && widget.useCurrentLocation!) {
      await provider.updateCurrentLocation(
          gracefully: widget.ignoreLocationPermissionErrors);
    }
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) searchBarController.clearOverlay();
        },
        child: FutureBuilder<PlaceProvider>(
          future: _futureProvider,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              provider = snapshot.data;
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider<PlaceProvider>.value(value: provider!),
                ],
                child: Stack(children: [
                  Scaffold(
                    key: ValueKey<int>(provider.hashCode),
                    resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                      key: appBarKey,
                      automaticallyImplyLeading: false,
                      iconTheme: Theme.of(context).iconTheme,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      titleSpacing: 0.0,
                      title: _buildSearchBar(context),
                    ),
                    body: _buildMapWithLocation(),
                  ),
                  _buildIntroModal(context),
                ]),
              );
            }

            final children = <Widget>[];
            if (snapshot.hasError) {
              children.addAll([
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                )
              ]);
            } else {
              children.add(const CircularProgressIndicator());
            }

            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              ),
            );
          },
        ));
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(width: 15),
        provider!.placeSearchingState == SearchingState.idle &&
                (widget.automaticallyImplyAppBarLeading ||
                    widget.onTapBack != null)
            ? IconButton(
                onPressed: () {
                  if (!showIntroModal ||
                      widget.introModalWidgetBuilder == null) {
                    provider?.debounceTimer?.cancel();
                    if (widget.onTapBack != null) {
                      widget.onTapBack!();
                      return;
                    }
                    Navigator.maybePop(context);
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                ),
                color: Colors.black.withValues(alpha: 0.5),
                padding: EdgeInsets.zero)
            : Container(),
        Expanded(
          child: AutoCompleteSearch(
              appBarKey: appBarKey,
              searchBarController: searchBarController,
              sessionToken: provider!.sessionToken,
              hintText: widget.hintText,
              searchingText: widget.searchingText,
              hidden: !widget.showSearchBar,
              debounceMilliseconds: widget.autoCompleteDebounceInMilliseconds,
              onPicked: (prediction) {
                if (mounted) {
                  _pickPrediction(prediction);
                }
              },
              onSearchFailed: (status) {
                if (widget.onAutoCompleteFailed != null) {
                  widget.onAutoCompleteFailed!(status);
                }
              },
              autocompleteOffset: widget.autocompleteOffset,
              autocompleteRadius: widget.autocompleteRadius,
              autocompleteLanguage: widget.autocompleteLanguage,
              autocompleteComponents: widget.autocompleteComponents,
              autocompleteTypes: widget.autocompleteTypes,
              strictbounds: widget.strictbounds,
              region: widget.region,
              initialSearchString: widget.initialSearchString,
              searchForInitialValue: widget.searchForInitialValue,
              autocompleteOnTrailingWhitespace:
                  widget.autocompleteOnTrailingWhitespace,
              voiceSearchEnabled: widget.voiceSearchEnabled,
              onVoiceSearchTapped: widget.onVoiceSearchTapped),
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  Future<void> _pickPrediction(Prediction prediction) async {
    if (prediction.placeId == null) return;
    provider!.placeSearchingState = SearchingState.searching;

    try {
      final PlacesDetailsResponse response =
          await provider!.places.getDetailsByPlaceId(
        prediction.placeId!,
        sessionToken: provider!.sessionToken,
        language: widget.autocompleteLanguage,
      );

      if (response.errorMessage?.isNotEmpty == true ||
          response.status == "REQUEST_DENIED") {
        if (widget.onAutoCompleteFailed != null) {
          widget.onAutoCompleteFailed!(response.status);
        }
        return;
      }

      provider!.selectedPlace =
          PickResult.fromPlaceDetailResult(response.result!);

      // V2: validate geometry before attempting to animate the camera.
      if (provider!.selectedPlace?.geometry == null) {
        debugPrint("Place detail result has no geometry — cannot move camera.");
        return;
      }

      // Prevents searching again by camera movement.
      provider!.isAutoCompleteSearching = true;

      await _moveTo(provider!.selectedPlace!.geometry!.location.lat,
          provider!.selectedPlace!.geometry!.location.lng);
    } finally {
      provider?.placeSearchingState = SearchingState.idle;
    }
  }

  Future<void> _moveTo(double latitude, double longitude) async {
    if (provider?.mapController == null) return;
    GoogleMapController? controller = provider!.mapController;
    try {
      await controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 16,
          ),
        ),
      );
    } catch (e) {
      // B15: guard against PlatformException on devices where the map
      // controller is not yet fully initialised when animateCamera is called.
      debugPrint('B15: animateCamera error in _moveTo: $e');
    }
  }

  Future<void> _moveToCurrentPosition() async {
    if (provider?.currentPosition == null) return;
    await _moveTo(provider!.currentPosition!.latitude,
        provider!.currentPosition!.longitude);
  }

  Widget _buildMapWithLocation() {
    if (provider!.currentPosition == null) {
      return _buildMap(widget.initialPosition);
    }
    return _buildMap(LatLng(provider!.currentPosition!.latitude,
        provider!.currentPosition!.longitude));
  }

  Widget _buildMap(LatLng initialTarget) {
    return GoogleMapPlacePicker(
      fullMotion: !widget.resizeToAvoidBottomInset,
      initialTarget: initialTarget,
      appBarKey: appBarKey,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      pinBuilder: widget.pinBuilder,
      onSearchFailed: widget.onGeocodingSearchFailed,
      debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
      enableMapTypeButton: widget.enableMapTypeButton,
      enableMyLocationButton: widget.enableMyLocationButton,
      usePinPointingSearch: widget.usePinPointingSearch,
      usePlaceDetailSearch: widget.usePlaceDetailSearch,
      onMapCreated: widget.onMapCreated,
      selectInitialPosition: widget.selectInitialPosition,
      language: widget.autocompleteLanguage,
      pickArea: widget.pickArea,
      forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
      hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
      selectText: widget.selectText,
      outsideOfPickAreaText: widget.outsideOfPickAreaText,
      onToggleMapType: () {
        if (provider == null) return;
        provider!.switchMapType();
        if (widget.onMapTypeChanged != null) {
          widget.onMapTypeChanged!(provider!.mapType);
        }
      },
      onMyLocation: () async {
        // Prevent to click many times in short period.
        if (provider == null) return;
        if (provider!.isOnUpdateLocationCooldown == false) {
          provider!.isOnUpdateLocationCooldown = true;
          Timer(Duration(seconds: widget.myLocationButtonCooldown), () {
            provider!.isOnUpdateLocationCooldown = false;
          });
          await provider!.updateCurrentLocation(
              gracefully: widget.ignoreLocationPermissionErrors);
          await _moveToCurrentPosition();
        }
      },
      onMoveStart: () {
        if (provider == null) return;
        searchBarController.reset();
      },
      onPlacePicked: (result) {
        searchBarController.clearOverlay();
        widget.onPlacePicked?.call(result);
      },
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      selectedPlaceButtonColor: widget.selectedPlaceButtonColor,
      initialZoom: widget.initialZoom,
      initialTilt: widget.initialTilt,
      initialBearing: widget.initialBearing,
      markers: widget.markers,
      polylines: widget.polylines,
      polygons: widget.polygons,
    );
  }

  Widget _buildIntroModal(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return showIntroModal && widget.introModalWidgetBuilder != null
          ? Stack(children: [
              const Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: Material(
                  type: MaterialType.canvas,
                  color: Color.fromARGB(128, 0, 0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: ClipRect(),
                ),
              ),
              widget.introModalWidgetBuilder!(context, () {
                if (mounted) {
                  setState(() {
                    showIntroModal = false;
                  });
                }
              })
            ])
          : Container();
    });
  }
}
