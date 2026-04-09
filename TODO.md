# TODO — maps_place_picker

Consolidated list of: security issues, bugs, deprecations, and relevant open issues/PRs from the upstream repository [fysoul17/google_maps_place_picker](https://github.com/fysoul17/google_maps_place_picker).

Items marked ✅ have already been addressed in this fork. Items not marked are pending.

---

## 🔒 Security

- [ ] **V1** – Restrict Google Maps API key (never ship raw key in binary; use server-side proxy or key restrictions in Google Cloud Console)
- [ ] **V2** – Add stricter validation of Places/Geocoding API responses (null-check geometry, handle partial responses)
- [ ] **V3** – Document / assert that `httpClient` must use HTTPS

---

## 🐛 Bugs

- [ ] **B1** – `selectInitialPosition: true` does not work correctly — `_searchByCameraLocation` is called before camera settles ([upstream #175](https://github.com/fysoul17/google_maps_place_picker/issues/175))
- [ ] **B2** – Infinite loading indicator on iOS when autocomplete `getDetailsByPlaceId` fails silently ([upstream #68](https://github.com/fysoul17/google_maps_place_picker/issues/68), [#78](https://github.com/fysoul17/google_maps_place_picker/issues/78)); fix: add `finally { placeSearchingState = Idle; }`
- [ ] **B3** – `RangeError` in `prediction_tile.dart` when `matchedSubString` offsets exceed description length ([upstream #161](https://github.com/fysoul17/google_maps_place_picker/issues/161)); fix: add bounds checking in `_buildPredictionText`
- [ ] **B4** – Autocomplete overlay not dismissed when "Select here" is tapped ([upstream #57](https://github.com/fysoul17/google_maps_place_picker/issues/57)); fix: call `searchBarController.clearOverlay()` in `onPlacePicked`
- [ ] **B5** – Potential null-dereference crash in `_searchByCameraLocation` if `cameraPosition` is null during early drag
- [ ] **B6** – Memory leak / error from `OverlayEntry.remove()` called after widget disposal; fix: check `overlayEntry!.mounted` or use try/catch
- [ ] **B7** – `PlaceProvider.debounceTimer` not cancelled on dispose; fix: override `dispose()` in `PlaceProvider`
- [ ] **B8** – After clicking on autocomplete search result, map rolls back to initial position ([upstream #87](https://github.com/fysoul17/google_maps_place_picker/issues/87), PR [#76](https://github.com/fysoul17/google_maps_place_picker/pull/76)): `SearchingState` not set to `Idle` after autocomplete camera animation completes on iOS
- [ ] **B9** – `selectedPlace` values always `null` when `usePlaceDetailSearch` is `false` ([upstream #109](https://github.com/fysoul17/google_maps_place_picker/issues/109)): geocoding result fields are not mapped
- [ ] **B10** – Autocomplete search result list starts above the search bar ([upstream #159](https://github.com/fysoul17/google_maps_place_picker/issues/159)): overlay offset calculation off in some layouts
- [ ] **B11** – `strictbounds` option does not correctly filter search results ([upstream #155](https://github.com/fysoul17/google_maps_place_picker/issues/155))
- [ ] **B12** – `region` filter doesn't restrict autocomplete results ([upstream #164](https://github.com/fysoul17/google_maps_place_picker/issues/164))
- [ ] **B13** – `onMapCreated` callback not called / not working ([upstream #99](https://github.com/fysoul17/google_maps_place_picker/issues/99), [#79](https://github.com/fysoul17/google_maps_place_picker/issues/79), [#116](https://github.com/fysoul17/google_maps_place_picker/issues/116))
- [ ] **B14** – Autocomplete search field overlaps results list / keyboard shows over field ([upstream #154](https://github.com/fysoul17/google_maps_place_picker/issues/154), [#77](https://github.com/fysoul17/google_maps_place_picker/issues/77))
- [ ] **B15** – App crash when loading map on some devices ([upstream #96](https://github.com/fysoul17/google_maps_place_picker/issues/96), [#69](https://github.com/fysoul17/google_maps_place_picker/issues/69))
- [ ] **B16** – Map coordinates inaccurate in rural/farm areas ([upstream #132](https://github.com/fysoul17/google_maps_place_picker/issues/132))
- [ ] **B17** – `After pressing on a location, circular progress indicator never stops` ([upstream #94](https://github.com/fysoul17/google_maps_place_picker/issues/94))

---

## ⚠️ Deprecations

- [ ] **D1** – Replace deprecated `Color.withAlpha/withGreen/withBlue` with `Color.withValues(alpha: ...)` (Flutter ≥3.27)
- [ ] **D2** – Replace `RawMaterialButton` with `IconButton.filled` / `ElevatedButton` (Flutter ≥3.19)
- [ ] **D3** – Fix forced `!` on `textTheme.bodyMedium.color` — use fallback `?? colorScheme.onSurface`
- [ ] **D4** – Remove deprecated `new` keyword in example code
- [ ] **D5** – Evaluate migrating from `flutter_google_maps_webservices` to Places API (New) direct HTTP — package unmaintained; Places API v1 not supported
- [ ] **D6** – Evaluate whether `EagerGestureRecognizer` workaround is still needed in `google_maps_flutter ^2.12.1`
- [ ] **D7** – ✅ Fixed: replaced `RaisedButton` with `ElevatedButton` (was upstream #174, #179, PR #180)
- [ ] **D8** – ✅ Fixed: `WidgetsBinding` null-aware warning (was upstream #173)
- [ ] **D9** – ✅ Fixed: `geolocator` updated to `^14.0.2` (was upstream #163, #185)

---

## ✨ Feature Requests (from upstream open issues)

- [ ] **F1** – Allow more GoogleMap widget customization (polylines, polygons, etc.) ([upstream #186](https://github.com/fysoul17/google_maps_place_picker/issues/186))
- [ ] **F2** – Expose `initialCameraPosition` parameter to allow custom zoom/bearing ([upstream #178](https://github.com/fysoul17/google_maps_place_picker/issues/178))
- [ ] **F3** – Add option to disable the search/autocomplete bar ([upstream #171](https://github.com/fysoul17/google_maps_place_picker/issues/171))
- [ ] **F4** – Allow customizing "Select here" button text ([upstream #117](https://github.com/fysoul17/google_maps_place_picker/issues/117), [#130](https://github.com/fysoul17/google_maps_place_picker/issues/130), PR [#126](https://github.com/fysoul17/google_maps_place_picker/pull/126)) — ✅ partially done via `selectText` param
- [ ] **F5** – Sort autocomplete results by distance from user (PR [#153](https://github.com/fysoul17/google_maps_place_picker/pull/153)): add `autocompleteSortByDistance` boolean param
- [ ] **F6** – Allow editing pick button text and color, hide search bar when not usable (PR [#181](https://github.com/fysoul17/google_maps_place_picker/pull/181))
- [ ] **F7** – Voice input for search text field ([upstream #177](https://github.com/fysoul17/google_maps_place_picker/issues/177))
- [ ] **F8** – `usePinPointingSearch = false` without losing the map dragging capability ([upstream #41](https://github.com/fysoul17/google_maps_place_picker/issues/41))
- [ ] **F9** – Search nearby places feature ([upstream #135](https://github.com/fysoul17/google_maps_place_picker/issues/135))
- [ ] **F10** – Search by coordinates ([upstream #83](https://github.com/fysoul17/google_maps_place_picker/issues/83))
- [ ] **F11** – Web platform support ([upstream #93](https://github.com/fysoul17/google_maps_place_picker/issues/93), [#131](https://github.com/fysoul17/google_maps_place_picker/issues/131))
- [ ] **F12** – Get latitude/longitude without making a network call ([upstream #151](https://github.com/fysoul17/google_maps_place_picker/issues/151))
- [ ] **F13** – Suggestion list should inherit app theme ([upstream #97](https://github.com/fysoul17/google_maps_place_picker/issues/97))
- [ ] **F14** – Expose street number and postal code from geocoding result ([upstream #119](https://github.com/fysoul17/google_maps_place_picker/issues/119))

---

## 🔧 Maintenance / Dependencies

- [ ] **M1** – Update `flutter_google_maps_webservices` or replace with direct API calls (current version ^1.1.1 is based on an unmaintained fork)
- [ ] **M2** – Add automated CI (GitHub Actions) with `flutter analyze` and `flutter test`
- [ ] **M3** – Add unit tests for `PlaceProvider`, `SearchProvider`, and `PickResult`
- [ ] **M4** – Add widget tests for `AutoCompleteSearch` and `GoogleMapPlacePicker`
- [ ] **M5** – Publish to pub.dev under new package name `maps_place_picker`
- [ ] **M6** – Update `flutter` + all dependencies (PR [#187](https://github.com/fysoul17/google_maps_place_picker/pull/187) from upstream: flutter/dart/deps upgrade)
- [ ] **M7** – Replace `permission_handler` (was causing iOS App Store rejections due to excess Info.plist entries — PR [#88](https://github.com/fysoul17/google_maps_place_picker/pull/88)) — ✅ already replaced with `geolocator`
- [ ] **M8** – Fix `package_info_plus` version constraint compatibility ([upstream #165](https://github.com/fysoul17/google_maps_place_picker/issues/165)) — ✅ updated to ^9.0.0

---

## 📝 Documentation

- [ ] **Doc1** – Write full API documentation (all `PlacePicker` parameters)
- [ ] **Doc2** – Add Android and iOS platform setup instructions to README (API key, AndroidManifest, Info.plist)
- [ ] **Doc3** – Add migration guide from `google_maps_place_picker` / `google_maps_place_picker_mb`
