import 'package:flutter/material.dart';
import 'package:maps_place_picker/maps_place_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ignore: implementation_imports, unused_import
import 'package:maps_place_picker/src/google_map_place_picker.dart'; // do not import this yourself
import 'dart:io' show Platform;

// Your api key storage.
import 'keys.dart';

// Only to control hybrid composition and the renderer in Android
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // Light Theme
  final ThemeData lightTheme = ThemeData.light().copyWith(
    // Background color of the FloatingCard
    cardColor: Colors.white,
  );

  // Dark Theme
  final ThemeData darkTheme = ThemeData.dark().copyWith(
    // Background color of the FloatingCard
    cardColor: Colors.grey,
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maps Place Picker Demo',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  static const kInitialPosition = LatLng(-33.8567844, 151.213108);

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PickResult? selectedPlace;
  bool _showPlacePickerInContainer = false;
  bool _showGoogleMapInContainer = false;

  bool _mapsInitialized = false;
  String _mapsRenderer = "latest";

  void initRenderer() {
    if (_mapsInitialized) return;
    if (widget.mapsImplementation is GoogleMapsFlutterAndroid) {
      // "auto" is the default — no explicit initializeWithRenderer call needed.
      if (_mapsRenderer == "latest") {
        (widget.mapsImplementation as GoogleMapsFlutterAndroid)
            .initializeWithRenderer(AndroidMapRenderer.latest);
      }
    }
    setState(() {
      _mapsInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Maps Place Picker Demo"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_mapsInitialized &&
                      widget.mapsImplementation
                          is GoogleMapsFlutterAndroid) ...[
                    Switch(
                        value: (widget.mapsImplementation
                                as GoogleMapsFlutterAndroid)
                            .useAndroidViewSurface,
                        onChanged: (value) {
                          setState(() {
                            (widget.mapsImplementation
                                    as GoogleMapsFlutterAndroid)
                                .useAndroidViewSurface = value;
                          });
                        }),
                    const Text("Hybrid Composition"),
                  ]
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_mapsInitialized &&
                      widget.mapsImplementation
                          is GoogleMapsFlutterAndroid) ...[
                    const Text("Renderer: "),
                    RadioGroup<String>(
                      groupValue: _mapsRenderer,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _mapsRenderer = value;
                          });
                        }
                      },
                      child: const Row(
                        children: [
                          const Radio<String>(value: "auto"),
                          const Text("Auto"),
                          const Radio<String>(value: "latest"),
                          const Text("Latest"),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
              !_showPlacePickerInContainer
                  ? ElevatedButton(
                      child: const Text("Load Place Picker"),
                      onPressed: () {
                        initRenderer();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return PlacePicker(
                                resizeToAvoidBottomInset:
                                    false, // only works in page mode, less flickery
                                apiKey: Platform.isAndroid
                                    ? APIKeys.androidApiKey
                                    : APIKeys.iosApiKey,
                                hintText: "Find a place ...",
                                searchingText: "Please wait ...",
                                selectText: "Select place",
                                outsideOfPickAreaText: "Place not in area",
                                initialPosition: HomePage.kInitialPosition,
                                useCurrentLocation: true,
                                selectInitialPosition: true,
                                usePinPointingSearch: true,
                                usePlaceDetailSearch: true,
                                zoomGesturesEnabled: true,
                                zoomControlsEnabled: true,
                                ignoreLocationPermissionErrors: true,
                                onMapCreated: (GoogleMapController controller) {
                                  debugPrint("Map created");
                                },
                                onPlacePicked: (PickResult result) {
                                  debugPrint(
                                      "Place picked: ${result.formattedAddress}");
                                  setState(() {
                                    selectedPlace = result;
                                    Navigator.of(context).pop();
                                  });
                                },
                                onMapTypeChanged: (MapType mapType) {
                                  debugPrint(
                                      "Map type changed to ${mapType.toString()}");
                                },
                              );
                            },
                          ),
                        );
                      },
                    )
                  : Container(),
              !_showPlacePickerInContainer
                  ? ElevatedButton(
                      child: const Text("Load Place Picker in Container"),
                      onPressed: () {
                        initRenderer();
                        setState(() {
                          _showPlacePickerInContainer = true;
                        });
                      },
                    )
                  : Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: PlacePicker(
                          apiKey: Platform.isAndroid
                              ? APIKeys.androidApiKey
                              : APIKeys.iosApiKey,
                          hintText: "Find a place ...",
                          searchingText: "Please wait ...",
                          selectText: "Select place",
                          initialPosition: HomePage.kInitialPosition,
                          useCurrentLocation: true,
                          selectInitialPosition: true,
                          usePinPointingSearch: true,
                          usePlaceDetailSearch: true,
                          zoomGesturesEnabled: true,
                          zoomControlsEnabled: true,
                          ignoreLocationPermissionErrors: true,
                          onPlacePicked: (PickResult result) {
                            setState(() {
                              selectedPlace = result;
                              _showPlacePickerInContainer = false;
                            });
                          },
                          onTapBack: () {
                            setState(() {
                              _showPlacePickerInContainer = false;
                            });
                          })),
              if (selectedPlace != null) ...[
                Text(selectedPlace!.formattedAddress!),
                Text("(lat: " +
                    selectedPlace!.geometry!.location.lat.toString() +
                    ", lng: " +
                    selectedPlace!.geometry!.location.lng.toString() +
                    ")"),
              ],
              // #region Google Map Example without provider
              _showPlacePickerInContainer
                  ? Container()
                  : ElevatedButton(
                      child: const Text("Toggle Google Map w/o Provider"),
                      onPressed: () {
                        initRenderer();
                        setState(() {
                          _showGoogleMapInContainer =
                              !_showGoogleMapInContainer;
                        });
                      },
                    ),
              !_showGoogleMapInContainer
                  ? Container()
                  : Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: MediaQuery.of(context).size.height * 0.25,
                      child: GoogleMap(
                        zoomGesturesEnabled: false,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        initialCameraPosition: const CameraPosition(
                            target: HomePage.kInitialPosition, zoom: 15),
                        mapType: MapType.normal,
                        myLocationEnabled: true,
                        onMapCreated: (GoogleMapController controller) {},
                        onCameraIdle: () {},
                        onCameraMoveStarted: () {},
                        onCameraMove: (CameraPosition position) {},
                      )),
              !_showGoogleMapInContainer ? Container() : const TextField(),
              // #endregion
            ],
          ),
        ));
  }
}
