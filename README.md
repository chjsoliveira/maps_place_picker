# maps_place_picker

A Flutter package that provides a **Pick a Place** UI powered by Google Maps —
drag the pin, search via autocomplete, restrict to an area, dark mode.

> **Platform support: Android & iOS.**
> This package wraps `google_maps_flutter` and the Google Places API (New), which
> require native SDKs and therefore run on **Android and iOS only**.
> Web/desktop support is not planned unless `google_maps_flutter` gains full
> feature parity on those platforms.

This is an actively maintained fork based on
[google_maps_place_picker_mb](https://github.com/chjsoliveira/google_maps_place_picker_mb),
which itself is a fork of
[google_maps_place_picker](https://github.com/fysoul17/google_maps_place_picker).

## Preview

![Place Picker Preview](doc/preview.gif)

## Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| Android  | ✅ | Native Google Maps SDK via `google_maps_flutter` |
| iOS      | ✅ | Native Google Maps SDK via `google_maps_flutter` |
| Web      | ⚠️ | Requires adding `google_maps_flutter_web` to your **app's** `pubspec.yaml` dependencies. Some features may have limited parity with the native implementations. |
| macOS    | ❌ | Not supported |
| Linux    | ❌ | Not supported |
| Windows  | ❌ | Not supported |

> **Note:** This package is not a Flutter plugin — it is a regular package that
> wraps `google_maps_flutter`. Platform support is therefore determined by the
> underlying plugins. For web support, add the following to your app's
> `pubspec.yaml`:
> ```yaml
> dependencies:
>   google_maps_flutter_web: ^0.5.0
> ```

## Features

- Pick a place by dragging the map pin (reverse geocoding)
- Pick a place by searching via Google Places Autocomplete
- Customizable UI (pin, floating card, intro modal)
- Restrict picking to a circular area (`pickArea`)
- Zoom controls (cross-platform, including iOS)
- Dark mode support

## Getting started

Add to `pubspec.yaml`:

```yaml
dependencies:
  maps_place_picker: ^1.0.0
```

Or, to track the latest commit directly from GitHub:

```yaml
dependencies:
  maps_place_picker:
    git:
      url: https://github.com/chjsoliveira/maps_place_picker
```

### 🔑 Security — API Key Setup

> **Important:** Never ship a raw Google Maps API key in your app binary. Anyone who reverse-engineers your APK/IPA can extract and misuse it.

Recommended steps:
1. Go to [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials).
2. Under **API restrictions**, restrict your key to only the APIs it needs (Maps SDK for Android/iOS, Places API, Geocoding API).
3. Under **Application restrictions**, add your Android package name + SHA-1 fingerprint (Android) or iOS bundle ID (iOS).
4. For server-side protection, pass a `proxyBaseUrl` so the raw key is never included in the app binary.

### Android Setup

1. Add your API key to `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_API_KEY"/>
```

2. Enable the following APIs in Google Cloud Console:
   - Maps SDK for Android
   - Places API
   - Geocoding API

### iOS Setup

1. Open `ios/Runner/AppDelegate.swift` and provide your API key:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

2. Add location permission strings to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your position on the map.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs location access to show your position on the map.</string>
```

3. Enable in Google Cloud Console:
   - Maps SDK for iOS
   - Places API
   - Geocoding API

## Usage

```dart
import 'package:maps_place_picker/maps_place_picker.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlacePicker(
      apiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
      initialPosition: LatLng(-33.8567844, 151.213108),
      useCurrentLocation: true,
      onPlacePicked: (PickResult result) {
        print(result.formattedAddress);
        Navigator.of(context).pop();
      },
    ),
  ),
);
```

See the `example/` directory for a complete demo application.

## PlacePicker Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `apiKey` | `String` | **required** | Google Maps API key |
| `initialPosition` | `LatLng` | **required** | Map center on open |
| `onPlacePicked` | `ValueChanged<PickResult>?` | — | Callback when user confirms selection |
| `useCurrentLocation` | `bool?` | `false` | Centre map on device location at startup |
| `desiredLocationAccuracy` | `LocationAccuracy` | `high` | GPS accuracy for "my location" |
| `hintText` | `String?` | `"Search here"` | Placeholder text in search bar |
| `searchingText` | `String?` | `"Searching..."` | Text shown while searching |
| `selectText` | `String?` | — | Label for the confirm button |
| `outsideOfPickAreaText` | `String?` | — | Label shown when pin is outside `pickArea` |
| `proxyBaseUrl` | `String?` | — | Proxy URL for API calls (key not needed in app) |
| `httpClient` | `BaseClient?` | — | Custom HTTP client (must use HTTPS) |
| `usePinPointingSearch` | `bool` | `true` | Reverse-geocode on camera idle |
| `usePlaceDetailSearch` | `bool` | `false` | Fetch full place details (extra API call) |
| `selectInitialPosition` | `bool` | `false` | Reverse-geocode the initial map position |
| `autocompleteLanguage` | `String?` | — | BCP-47 language code for autocomplete |
| `autocompleteTypes` | `List<String>?` | — | Place type filter |
| `autocompleteComponents` | `List<Component>?` | — | Country/region filter |
| `autocompleteRadius` | `num?` | — | Search radius in metres |
| `autocompleteOffset` | `num?` | — | Character offset for autocomplete |
| `strictbounds` | `bool?` | — | Restrict results to the autocomplete radius |
| `region` | `String?` | — | Region bias for search results (ISO 3166-1 alpha-2 country code, e.g. `"US"`, `"BR"`) |
| `pickArea` | `CircleArea?` | — | Restrict valid picks to a circle |
| `enableMapTypeButton` | `bool` | `true` | Show the map-type toggle button |
| `enableMyLocationButton` | `bool` | `true` | Show the "my location" button |
| `myLocationButtonCooldown` | `int` | `10` | Seconds between location updates |
| `zoomGesturesEnabled` | `bool` | `true` | Allow pinch-to-zoom |
| `zoomControlsEnabled` | `bool` | `false` | Show +/− zoom buttons |
| `forceSearchOnZoomChanged` | `bool` | `false` | Search again when only zoom changes |
| `hidePlaceDetailsWhenDraggingPin` | `bool` | `true` | Hide the floating card while dragging |
| `resizeToAvoidBottomInset` | `bool` | `true` | Resize body to avoid keyboard |
| `automaticallyImplyAppBarLeading` | `bool` | `true` | Show back arrow in app bar |
| `autocompleteOnTrailingWhitespace` | `bool` | `false` | Trigger autocomplete on trailing space |
| `ignoreLocationPermissionErrors` | `bool` | `false` | Silently ignore location errors |
| `initialSearchString` | `String?` | — | Pre-fill the search field |
| `searchForInitialValue` | `bool` | `false` | Auto-search the initial string |
| `autoCompleteDebounceInMilliseconds` | `int` | `500` | Debounce for autocomplete |
| `cameraMoveDebounceInMilliseconds` | `int` | `750` | Debounce for camera-move search |
| `initialMapType` | `MapType` | `normal` | Starting map style |
| `selectedPlaceWidgetBuilder` | `SelectedPlaceWidgetBuilder?` | — | Custom floating card builder |
| `pinBuilder` | `PinBuilder?` | — | Custom map pin builder |
| `introModalWidgetBuilder` | `IntroModalWidgetBuilder?` | — | Custom intro modal builder |
| `onMapCreated` | `MapCreatedCallback?` | — | Called when `GoogleMapController` is ready |
| `onAutoCompleteFailed` | `ValueChanged<String>?` | — | Autocomplete error callback |
| `onGeocodingSearchFailed` | `ValueChanged<String>?` | — | Geocoding error callback |
| `onMapTypeChanged` | `Function(MapType)?` | — | Map type change callback |
| `onCameraMoveStarted` | `Function(PlaceProvider)?` | — | Camera move started callback |
| `onCameraMove` | `CameraPositionCallback?` | — | Camera moving callback |
| `onCameraIdle` | `Function(PlaceProvider)?` | — | Camera settled callback |
| `onTapBack` | `VoidCallback?` | — | Override back button behaviour |
| `showSearchBar` | `bool` | `true` | Show the autocomplete search bar; set to `false` for pure pin-drag mode |
| `selectedPlaceButtonColor` | `Color?` | `Colors.lightGreen` | Override color of the "Select here" button when the pin is inside `pickArea` |
| `initialZoom` | `double` | `15.0` | Initial camera zoom level |
| `initialTilt` | `double` | `0.0` | Initial camera tilt in degrees |
| `initialBearing` | `double` | `0.0` | Initial camera bearing in degrees clockwise from north |
| `voiceSearchEnabled` | `bool` | `false` | Show a microphone button in the search bar; consumer handles speech recognition |
| `onVoiceSearchTapped` | `VoidCallback?` | — | Called when the microphone button is tapped (requires `voiceSearchEnabled: true`) |
| `markers` | `Set<Marker>?` | — | Extra markers to display on the map alongside the built-in draggable pin |
| `polylines` | `Set<Polyline>?` | — | Polylines to overlay on the map |
| `polygons` | `Set<Polygon>?` | — | Polygons to overlay on the map |

## Migrating from `google_maps_place_picker` / `google_maps_place_picker_mb`

### From `google_maps_place_picker` (fysoul17)

1. Replace the dependency in `pubspec.yaml`:

```yaml
# Remove:
# google_maps_place_picker: ...

# Add:
maps_place_picker: ^1.0.0
```

2. Update all imports:

```dart
// Before:
import 'package:google_maps_place_picker/google_maps_place_picker.dart';

// After:
import 'package:maps_place_picker/maps_place_picker.dart';
```

3. `RaisedButton` has been replaced — no code changes needed.
4. `geolocator` is now used instead of `permission_handler` — no code changes needed.
5. `flutter_google_maps_webservices` is no longer a dependency. Types such as
   `Geometry`, `AddressComponent`, `Prediction`, and `Component` are exported
   directly from `maps_place_picker`.
6. `PickResult` fields `id`, `reference`, `icon`, `scope`, and `utcOffset` have been
   removed. `url` is now `googleMapsUri`.

### From `google_maps_place_picker_mb` (chjsoliveira)

Same steps as above — only the package name and import path change.

### Breaking changes vs upstream

- Minimum Flutter SDK: **3.38.0** (Dart 3.9.2)
- `flutter_google_maps_webservices` is no longer a transitive dependency

## Publishing to pub.dev

> These steps are for maintainers preparing a release.

- [ ] Update `version` in `pubspec.yaml`
- [ ] Update `CHANGELOG.md` with release notes
- [ ] Ensure `flutter analyze` passes with no issues
- [ ] Run `flutter test`
- [ ] Run `dart pub publish --dry-run` to catch any issues
- [ ] Tag the release: `git tag v<version> && git push --tags`
- [ ] Run `dart pub publish`

---
