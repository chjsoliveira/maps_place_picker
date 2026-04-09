import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_place_picker/maps_place_picker.dart';
import 'package:maps_place_picker/providers/place_provider.dart';
import 'package:maps_place_picker/src/components/animated_pin.dart';
import 'package:maps_place_picker/src/models/geocoding_result.dart';
import 'package:maps_place_picker/src/services/places_service.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

typedef SelectedPlaceWidgetBuilder = Widget Function(
  BuildContext context,
  PickResult? selectedPlace,
  SearchingState state,
  bool isSearchBarFocused,
);

typedef PinBuilder = Widget Function(
  BuildContext context,
  PinState state,
);

class GoogleMapPlacePicker extends StatelessWidget {
  const GoogleMapPlacePicker({
    Key? key,
    required this.initialTarget,
    required this.appBarKey,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.onSearchFailed,
    this.onMoveStart,
    this.onMapCreated,
    this.debounceMilliseconds,
    this.enableMapTypeButton,
    this.enableMyLocationButton,
    this.onToggleMapType,
    this.onMyLocation,
    this.onPlacePicked,
    this.usePinPointingSearch,
    this.usePlaceDetailSearch,
    this.selectInitialPosition,
    this.language,
    this.pickArea,
    this.forceSearchOnZoomChanged,
    this.hidePlaceDetailsWhenDraggingPin,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.selectText,
    this.outsideOfPickAreaText,
    this.zoomGesturesEnabled = true,
    this.zoomControlsEnabled = false,
    this.fullMotion = false,
  }) : super(key: key);

  final LatLng initialTarget;
  final GlobalKey appBarKey;

  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;
  final PinBuilder? pinBuilder;

  final ValueChanged<String>? onSearchFailed;
  final VoidCallback? onMoveStart;
  final MapCreatedCallback? onMapCreated;
  final VoidCallback? onToggleMapType;
  final VoidCallback? onMyLocation;
  final ValueChanged<PickResult>? onPlacePicked;

  final int? debounceMilliseconds;
  final bool? enableMapTypeButton;
  final bool? enableMyLocationButton;

  final bool? usePinPointingSearch;
  final bool? usePlaceDetailSearch;

  final bool? selectInitialPosition;

  final String? language;
  final CircleArea? pickArea;

  final bool? forceSearchOnZoomChanged;
  final bool? hidePlaceDetailsWhenDraggingPin;

  /// GoogleMap pass-through events:
  final Function(PlaceProvider)? onCameraMoveStarted;
  final CameraPositionCallback? onCameraMove;
  final Function(PlaceProvider)? onCameraIdle;

  // strings
  final String? selectText;
  final String? outsideOfPickAreaText;

  /// Zoom feature toggle
  final bool zoomGesturesEnabled;
  final bool zoomControlsEnabled;

  /// Use never scrollable scroll-view with maximum dimensions to prevent unnecessary re-rendering.
  final bool fullMotion;

  _searchByCameraLocation(PlaceProvider provider) async {
    // Guard: map must be ready before searching.
    if (provider.mapController == null) {
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    // We don't want to search location again if camera location is changed by zooming in/out.
    if (forceSearchOnZoomChanged == false &&
        provider.prevCameraPosition != null &&
        provider.prevCameraPosition!.target.latitude ==
            provider.cameraPosition!.target.latitude &&
        provider.prevCameraPosition!.target.longitude ==
            provider.cameraPosition!.target.longitude) {
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    if (provider.cameraPosition == null) {
      // Camera position cannot be determined for some reason ...
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    provider.placeSearchingState = SearchingState.searching;

    // B16: capture the exact pin position before the async geocoding call.
    final double pinLat = provider.cameraPosition!.target.latitude;
    final double pinLng = provider.cameraPosition!.target.longitude;

    final GeocodingResponse response =
        await provider.geocoding.searchByLocation(
      pinLat,
      pinLng,
      language: language,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      debugPrint("Camera Location Search Error: ${response.errorMessage}");
      if (onSearchFailed != null) {
        onSearchFailed!(response.status);
      }
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    if (response.results.isEmpty) {
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    // V2: validate that the result has usable geometry before proceeding.
    final firstResult = response.results[0];
    if (firstResult.geometry == null) {
      debugPrint("Camera Location Search: result has no geometry, skipping.");
      provider.placeSearchingState = SearchingState.idle;
      return;
    }

    if (usePlaceDetailSearch!) {
      final PlacesDetailsResponse detailResponse =
          await provider.places.getDetailsByPlaceId(
        firstResult.placeId,
        language: language,
      );

      if (detailResponse.errorMessage?.isNotEmpty == true ||
          detailResponse.status == "REQUEST_DENIED") {
        debugPrint(
            "Fetching details by placeId Error: ${detailResponse.errorMessage}");
        if (onSearchFailed != null) {
          onSearchFailed!(detailResponse.status);
        }
        provider.placeSearchingState = SearchingState.idle;
        return;
      }

      // V2: validate detail result geometry.
      if (detailResponse.result?.geometry == null) {
        debugPrint("Place detail result has no geometry, falling back to geocoding result.");
        // B16: use the camera position as the authoritative location.
        provider.selectedPlace = PickResult.fromGeocodingResult(
          firstResult,
          cameraLat: pinLat,
          cameraLng: pinLng,
        );
      } else {
        provider.selectedPlace =
            PickResult.fromPlaceDetailResult(detailResponse.result!);
      }
    } else {
      // B16: use the exact pin position rather than the geocoding centroid.
      provider.selectedPlace = PickResult.fromGeocodingResult(
        firstResult,
        cameraLat: pinLat,
        cameraLng: pinLng,
      );
    }

    provider.placeSearchingState = SearchingState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (this.fullMotion)
          SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      _buildGoogleMap(context),
                      _buildPin(),
                    ],
                  ))),
        if (!this.fullMotion) ...[_buildGoogleMap(context), _buildPin()],
        _buildFloatingCard(),
        _buildMapIcons(context),
        _buildZoomButtons()
      ],
    );
  }

  Widget _buildGoogleMapInner(PlaceProvider provider, MapType mapType) {
    CameraPosition initialCameraPosition =
        CameraPosition(target: this.initialTarget, zoom: 15);
    return GoogleMap(
      zoomGesturesEnabled: this.zoomGesturesEnabled,
      zoomControlsEnabled:
          false, // we use our own implementation that supports iOS as well, see _buildZoomButtons()
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      initialCameraPosition: initialCameraPosition,
      mapType: mapType,
      myLocationEnabled: true,
      circles: pickArea != null && pickArea!.radius > 0
          ? Set<Circle>.from([pickArea])
          : Set<Circle>(),
      onMapCreated: (GoogleMapController controller) {
        provider.mapController = controller;
        provider.setCameraPosition(null);
        provider.pinState = PinState.idle;

        // When selectInitialPosition is true, defer the search until the
        // first onCameraIdle so the camera has fully settled on the initial
        // position (fixes upstream issue #175).
        if (selectInitialPosition!) {
          provider.pendingInitialSearch = true;
        }
        onMapCreated?.call(controller);
      },
      onCameraIdle: () {
        // Trigger the deferred initial-position search on the first idle.
        if (provider.pendingInitialSearch) {
          provider.pendingInitialSearch = false;
          _searchByCameraLocation(provider);
          return;
        }

        if (provider.isAutoCompleteSearching) {
          provider.isAutoCompleteSearching = false;
          provider.pinState = PinState.idle;
          provider.placeSearchingState = SearchingState.idle;
          return;
        }
        // Perform search only if the setting is to true.
        if (usePinPointingSearch!) {
          // Search current camera location only if camera has moved (dragged) before.
          if (provider.pinState == PinState.dragging) {
            // Cancel previous timer.
            if (provider.debounceTimer?.isActive ?? false) {
              provider.debounceTimer!.cancel();
            }
            provider.debounceTimer =
                Timer(Duration(milliseconds: debounceMilliseconds!), () {
              _searchByCameraLocation(provider);
            });
          }
        }
        provider.pinState = PinState.idle;
        onCameraIdle?.call(provider);
      },
      onCameraMoveStarted: () {
        onCameraMoveStarted?.call(provider);
        provider.setPrevCameraPosition(provider.cameraPosition);
        // Cancel any other timer.
        provider.debounceTimer?.cancel();
        // Only mark as dragging for genuine user gestures, not for the
        // programmatic camera animation triggered by autocomplete (B8).
        if (!provider.isAutoCompleteSearching) {
          provider.pinState = PinState.dragging;
          // Begins the search state if the hide details is enabled
          if (this.hidePlaceDetailsWhenDraggingPin!) {
            provider.placeSearchingState = SearchingState.searching;
          }
          onMoveStart?.call();
        }
      },
      onCameraMove: (CameraPosition position) {
        provider.setCameraPosition(position);
        onCameraMove?.call(position);
      },
      // gestureRecognizers make it possible to navigate the map when it's a
      // child in a scroll view e.g ListView, SingleChildScrollView...
      // TODO(D6): re-evaluate whether EagerGestureRecognizer is still required
      // with google_maps_flutter ^2.12.1 (current constraint in pubspec.yaml) —
      // the nested scroll-view workaround may have been resolved upstream.
      gestureRecognizers: <Factory<EagerGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    return Selector<PlaceProvider, MapType>(
        selector: (_, provider) => provider.mapType,
        builder: (_, data, __) => this._buildGoogleMapInner(
            PlaceProvider.of(context, listen: false), data));
  }

  Widget _buildPin() {
    return Center(
      child: Selector<PlaceProvider, PinState>(
        selector: (_, provider) => provider.pinState,
        builder: (context, state, __) {
          if (pinBuilder == null) {
            return _defaultPinBuilder(context, state);
          } else {
            return Builder(
                builder: (builderContext) =>
                    pinBuilder!(builderContext, state));
          }
        },
      ),
    );
  }

  Widget _defaultPinBuilder(BuildContext context, PinState state) {
    if (state == PinState.preparing) {
      return Container();
    } else if (state == PinState.idle) {
      return Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.place, size: 36, color: Colors.red),
                SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedPin(
                    child: Icon(Icons.place, size: 36, color: Colors.red)),
                SizedBox(height: 42),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFloatingCard() {
    return Selector<PlaceProvider,
        Tuple4<PickResult?, SearchingState, bool, PinState>>(
      selector: (_, provider) => Tuple4(
          provider.selectedPlace,
          provider.placeSearchingState,
          provider.isSearchBarFocused,
          provider.pinState),
      builder: (context, data, __) {
        if ((data.item1 == null && data.item2 == SearchingState.idle) ||
            data.item3 == true ||
            data.item4 == PinState.dragging &&
                this.hidePlaceDetailsWhenDraggingPin!) {
          return Container();
        } else {
          if (selectedPlaceWidgetBuilder == null) {
            return _defaultPlaceWidgetBuilder(context, data.item1, data.item2);
          } else {
            return Builder(
                builder: (builderContext) => selectedPlaceWidgetBuilder!(
                    builderContext, data.item1, data.item2, data.item3));
          }
        }
      },
    );
  }

  Widget _buildZoomButtons() {
    return Selector<PlaceProvider, Tuple2<GoogleMapController?, LatLng?>>(
      selector: (_, provider) => Tuple2<GoogleMapController?, LatLng?>(
          provider.mapController, provider.cameraPosition?.target),
      builder: (context, data, __) {
        if (!this.zoomControlsEnabled ||
            data.item1 == null ||
            data.item2 == null) {
          return Container();
        } else {
          return Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1 - 3.6,
            right: 2,
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.15 - 13,
                height: 107,
                child: Column(
                  children: <Widget>[
                    IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          try {
                            double currentZoomLevel =
                                await data.item1!.getZoomLevel();
                            currentZoomLevel = currentZoomLevel + 2;
                            await data.item1!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: data.item2!,
                                  zoom: currentZoomLevel,
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint('B15: animateCamera error (zoom in): $e');
                          }
                        }),
                    SizedBox(height: 2),
                    IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () async {
                          try {
                            double currentZoomLevel =
                                await data.item1!.getZoomLevel();
                            currentZoomLevel = currentZoomLevel - 2;
                            if (currentZoomLevel < 0) currentZoomLevel = 0;
                            await data.item1!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: data.item2!,
                                  zoom: currentZoomLevel,
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint('B15: animateCamera error (zoom out): $e');
                          }
                        }),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _defaultPlaceWidgetBuilder(
      BuildContext context, PickResult? data, SearchingState state) {
    return FloatingCard(
      bottomPosition: MediaQuery.of(context).size.height * 0.1,
      leftPosition: MediaQuery.of(context).size.width * 0.15,
      rightPosition: MediaQuery.of(context).size.width * 0.15,
      width: MediaQuery.of(context).size.width * 0.7,
      borderRadius: BorderRadius.circular(12.0),
      elevation: 4.0,
      color: Theme.of(context).cardColor,
      child: state == SearchingState.searching
          ? _buildLoadingIndicator()
          : _buildSelectionDetails(context, data!),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 48,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildSelectionDetails(BuildContext context, PickResult result) {
    // B9: guard against null geometry (can happen when usePlaceDetailSearch=false
    // and the geocoding API returns a result without geometry).
    bool canBePicked = pickArea == null ||
        pickArea!.radius <= 0 ||
        (result.geometry != null &&
            Geolocator.distanceBetween(
                    pickArea!.center.latitude,
                    pickArea!.center.longitude,
                    result.geometry!.location.lat,
                    result.geometry!.location.lng) <=
                pickArea!.radius);
    WidgetStateColor buttonColor = WidgetStateColor.resolveWith(
        (states) => canBePicked ? Colors.lightGreen : Colors.red);
    return Container(
      margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Text(
            result.formattedAddress ?? 'Address unavailable',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          (canBePicked && (selectText?.isEmpty ?? true)) ||
                  (!canBePicked && (outsideOfPickAreaText?.isEmpty ?? true))
              ? SizedBox.fromSize(
                  size: Size(56, 56), // button width and height
                  child: ClipOval(
                    child: Material(
                      child: InkWell(
                          overlayColor: buttonColor,
                          onTap: () {
                            if (canBePicked) {
                              onPlacePicked!(result);
                            }
                          },
                          child: Icon(
                              canBePicked
                                  ? Icons.check_sharp
                                  : Icons.app_blocking_sharp,
                              color: buttonColor)),
                    ),
                  ),
                )
              : SizedBox.fromSize(
                  size: Size(MediaQuery.of(context).size.width * 0.8,
                      56), // button width and height
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Material(
                      child: InkWell(
                          overlayColor: buttonColor,
                          onTap: () {
                            if (canBePicked) {
                              onPlacePicked!(result);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  canBePicked
                                      ? Icons.check_sharp
                                      : Icons.app_blocking_sharp,
                                  color: buttonColor),
                              SizedBox.fromSize(size: Size(10, 0)),
                              Text(
                                  canBePicked
                                      ? selectText!
                                      : outsideOfPickAreaText!,
                                  style: TextStyle(color: buttonColor))
                            ],
                          )),
                    ),
                  ),
                )
        ],
      ),
    );
  }

  Widget _buildMapIcons(BuildContext context) {
    if (appBarKey.currentContext == null) {
      return Container();
    }
    final RenderBox appBarRenderBox =
        appBarKey.currentContext!.findRenderObject() as RenderBox;
    return Positioned(
      top: appBarRenderBox.size.height,
      right: 15,
      child: Column(
        children: <Widget>[
          enableMapTypeButton!
              ? SizedBox(
                  width: 35,
                  height: 35,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.black54
                              : Colors.white,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                      elevation: 4.0,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: onToggleMapType,
                    child: const Icon(Icons.layers),
                  ),
                )
              : Container(),
          SizedBox(height: 10),
          enableMyLocationButton!
              ? SizedBox(
                  width: 35,
                  height: 35,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.black54
                              : Colors.white,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                      elevation: 4.0,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: onMyLocation,
                    child: const Icon(Icons.my_location),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
