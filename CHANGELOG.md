## [1.0.0] - 10/Apr/2026

First publication to pub.dev.
Ported and fully reworked from `google_maps_place_picker_mb` (chjsoliveira fork, v3.2.0),
which itself derives from [fysoul17/google_maps_place_picker](https://github.com/fysoul17/google_maps_place_picker).

### ⚠️ Breaking changes vs the upstream package

- **Removed** `flutter_google_maps_webservices` dependency. Types such as
  `Geometry`, `AddressComponent`, `Prediction`, and `Component` are now exported
  directly from `maps_place_picker`.
- `PickResult` fields `id`, `reference`, `icon`, `scope`, and `utcOffset` have been
  removed — they mapped to deprecated Places API v1 fields with no equivalent in the
  Places API (New). `url` is now `googleMapsUri`.
- Minimum Flutter SDK: **3.27.0** (Dart 3.6.0).

### Features

- Pick a place by dragging the map pin (reverse geocoding via Geocoding API).
- Pick a place by typing in the autocomplete search bar (Places API — New).
- Customisable pin, floating card, and intro modal via builder callbacks.
- Restrict valid picks to a circular area (`pickArea`).
- Zoom controls (cross-platform, including iOS).
- Dark mode support.
- 40+ named parameters — see README for the full API reference.

### Bug fixes & improvements (vs upstream)

- **Places API (New)** — replaced unmaintained `flutter_google_maps_webservices`
  with direct HTTP calls to `https://places.googleapis.com/v1/`.
- **B1** `selectInitialPosition: true` now waits for the first `onCameraIdle`
  before reverse-geocoding, preventing a race condition at startup.
- **B2** Added `finally` block to `_pickPrediction` so the loading indicator
  always resets, even when the Places Detail call fails silently.
- **B3** Bounds-checked `matchedSubString` offsets to prevent `RangeError` when
  selecting from autocomplete.
- **B4** Autocomplete overlay is dismissed when the user taps "Select here".
- **B5** Early-return guard when `mapController` is `null` during initial drag.
- **B6** `OverlayEntry.remove()` wrapped in try-catch to prevent errors after
  the parent route is popped.
- **B7** `debounceTimer` cancelled in `PlaceProvider.dispose()`.
- **B8** Fixed iOS map rollback after autocomplete pick by correcting
  `isAutoCompleteSearching` reset timing.
- **B9** `selectedPlace` fields are now populated correctly when
  `usePlaceDetailSearch = false`.
- **B10** Autocomplete overlay offset uses `localToGlobal` for correct placement
  in non-standard layouts.
- **B11** `strictbounds: true` now uses `locationRestriction` (hard boundary)
  instead of being silently ignored.
- **B12** `region` is forwarded as `regionCode` to the New API for proper biasing.
- **B14** Autocomplete results no longer overlap the on-screen keyboard.
- **B15** `animateCamera` calls wrapped in try-catch to prevent crashes on devices
  where the map controller is not yet fully initialised.
- **B16** `PickResult.geometry.location` reflects the exact pin position rather
  than the geocoding centroid, fixing inaccurate coordinates in rural areas.
- **D1–D6** Replaced all deprecated Flutter APIs (`withAlpha`, `RawMaterialButton`,
  forced `!` on nullable `Color`, `new` keyword, `EagerGestureRecognizer` reviewed).
- **M2** GitHub Actions CI: `flutter analyze` + `flutter test`.
- **M3/M4** Unit and widget tests for models, services, providers, and search.
- **V1–V3** API key best-practice documentation; stricter API-response validation.

## [3.1.5] - 21/Mar/2026

- Update geolocator to ^14.0.2 for compatibility with latest apps
- Upgrade packages

## [3.1.2] - 13/Sep/2023

- Fix potential crash on hesitant camera movements #67
- Replace obsolete dependencies to support the major release of `http`

## [3.1.1] - 14/Jul/2023

- Fix `package_info_plus` compatibility

## [3.1.0] - 14/Jul/2023

- Graceful location requests via `ignoreLocationPermissionErrors`
- Better zoom controls that look more consistent with the overall experience
- Upgrade packages

## [3.0.2] - 10/May/2023

- Fix getting current location 
- Upgrade `google_maps_flutter` package to 2.2.6

## [3.0.1] - 06/Feb/2023

- Search TextBox border themable for all states
- Fix crash by replacing FlutterLocation with Geolocator (#51)

## [3.0.0] - 22/Dec/2022

- Upgrade packages
- Added latest renderer support for Android
- Flutter 2 support has been dropped in consequence

## [2.0.0-mb.22] - 09/Aug/2022

- Upgrade packages
- Fix shadow clipping on AutoCompleteSearch
- Streamline shadows
- Prevent re-render of map when toggling the keyboard

## [2.0.0-mb.21] - 31/Jul/2022

- Upgrade geolocator

## [2.0.0-mb.20] - 06/Jun/2022

- Revert previous changes and solve null-aware operation warning in a way that the package is warn-free for Flutter 2 and 3.

## [2.0.0-mb.19] - 26/May/2022

- Remove unnecessary null-aware operation `!` that throws a compiler warning since Flutter 3.0.1

## [2.0.0-mb.18] - 14/May/2022

- Update packages for Flutter 3.0.0

## [2.0.0-mb.17] - 28/Apr/2022

- Add custom zoom buttons

## [2.0.0-mb.16] - 21/Apr/2022

- Add [FVM](https://fvm.app) config
- Add `onMapTypeChanged` callback event

## [2.0.0-mb.15] - 06/Mar/2022

- Fix autocomplete search vertical offset in containers

## [2.0.0-mb.14] - 24/Feb/2022

- Update geolocator
- onMapCreated event pass-through

## [2.0.0-mb.13] - 08/Dec/2021

- Update google_maps_webservice
- Update geolocator

## [2.0.0-mb.11] - 16/Nov/2021

- Upgrade packages and target platforms

## [2.0.0-mb.10] - 25/Oct/2021

- Fix passing-through GoogleMap widget callbacks

## [2.0.0-mb.9] - 08/Sep/2021

- Fix permanent loading indicator when using search bar on iOS

## [2.0.0-mb.8] - 08/Sep/2021

- Fix old address showing up when moving the pin

## [2.0.0-mb.7] - 08/Sep/2021

- Remove automatic scrolling to pick area when trying to pick an invalid location
- Allow providing button texts
- Allow providing an introduction modal

## [2.0.0-mb.6] - 03/Sep/2021

- Add possibility to use custom back navigation event

## [2.0.0-mb.5] - 19/Aug/2021

- Provide additional `PlaceProvider` on some `GoogleMap` events

## [2.0.0-mb.4] - 19/Aug/2021

- Hot fix regarding `GoogleMap` event access

## [2.0.0-mb.3] - 19/Aug/2021

- Updated colors and shapes
- Expose essential `GoogleMap` events

## [2.0.0-mb.2] - 19/Aug/2021

- Fixed runtime and deploy issues on iOS

## [2.0.0-mb.1] - 18/Aug/2021

- Forked
- Added allowed pick area feature
- Improved place details widget

## [2.0.0-nullsafety.3] - 18/Mar/2021

- Updated google_maps_webservice to 0.0.20-nullsafety.2

## [2.0.0-nullsafety.2] - 17/Mar/2021

- Fixed bugs (PR #106, #108)

## [2.0.0-nullsafety.1] - 11/Mar/2021

- Updated to handle nullsafety.

## [2.0.0-nullsafety.0] - 08/Mar/2021

- Updated to solve nullsafety issues

## [1.0.1] - 23/Nov/2020

- Fixed bug related to infinite loading.

## [1.0.0] - 05/Oct/2020

- Updated google_maps_flutter version to 1.0.2 which is now out of developer preview.

## [0.10.0] - 09/Sep/2020

- Updated geolocator version to 6.0.0.
- Added permission package to improve checking permissions.
- Added gestureRecognizers to make it possible to navigate the map when it's a child in a scroll view.

## [0.9.5] - 02/Aug/2020

- Added [autocompleteOnTrailingWhitespace] parameter.

## [0.9.4] - 21/Apr/2020

- Updated geolocator version to 5.3.1.

## [0.9.3] - 15/Apr/2020

- Updated google_maps_flutter package to 0.5.25+3

## [0.9.2] - 09/Apr/2020

- Added [automaticallyImplyAppBarLeading] parameter to allow removing back button on the app bar if needed.

## [0.9.1] - 05/Apr/2020

- Added [forceSearchOnZoomChanged] parameter.

## [0.9.0] - 11/Mar/2020

- Hot fix. Fixed bug that auto complete search prediction layout is not displaying.

## [0.8.0] - 07/Mar/2020

- New feature. [initialSearchString] and [searchForInitialValue] parameters.

## [0.1.0] - 23/Jan/2020

- Initial release
