# TODO — maps_place_picker

Consolidated list of: security issues, bugs, deprecations, and relevant open issues/PRs from the upstream repository [fysoul17/google_maps_place_picker](https://github.com/fysoul17/google_maps_place_picker).

Items marked ✅ have already been addressed in this fork. Items not marked are pending.

Story point scale: 1 = trivial · 2 = simple · 3 = moderate · 5 = complex · 8 = epic

---

## ✅ Sprint 1 — Critical Bugs & Quick Deprecations (24 SP) — DONE

| ID | Description | SP | Status |
|----|-------------|----|----|
| B7 | `PlaceProvider.debounceTimer` not cancelled on dispose | 1 | ✅ |
| B2/B17 | Infinite loading / progress never stops — add `finally` to `_pickPrediction` | 2 | ✅ |
| B4 | Autocomplete overlay not dismissed when "Select here" tapped | 2 | ✅ |
| B5 | Null-dereference crash if `mapController` is null during early drag | 1 | ✅ |
| B6 | `OverlayEntry.remove()` called after widget disposal — wrap in try/catch | 1 | ✅ |
| B3 | `RangeError` when `matchedSubString` offsets exceed description length | 2 | ✅ |
| D3 | Forced `!` on `textTheme.bodyMedium.color` — use `?? colorScheme.onSurface` | 1 | ✅ |
| D4 | Remove deprecated `new` keyword in example code | 1 | ✅ |
| D1 | Replace `Color.withAlpha/withGreen/withBlue` with `Color.withValues(alpha:)` | 2 | ✅ |
| D2 | Replace `RawMaterialButton` with `ElevatedButton` | 2 | ✅ |
| B1 | `selectInitialPosition: true` fires before camera settles — delay to first `onCameraIdle` | 3 | ✅ |
| V3 | Document that `httpClient` must use HTTPS | 1 | ✅ |
| D6 | Evaluate `EagerGestureRecognizer` workaround (add comment, review necessity) | 2 | ✅ |
| Doc2 | Add Android & iOS platform setup instructions to README | 3 | ✅ |

---

## ✅ Sprint 2 — Security, Data Integrity & CI (26 SP) — DONE

| ID | Description | SP | Status |
|----|-------------|----|----|
| V1 | Document API key restriction best practices in README | 3 | ✅ |
| V2 | Stricter validation of Places/Geocoding API responses (null-check geometry) | 3 | ✅ |
| B9 | `selectedPlace` values null when `usePlaceDetailSearch = false` — fix field mapping | 3 | ✅ |
| B8 | Map rolls back after autocomplete pick on iOS — fix `isAutoCompleteSearching` timing | 3 | ✅ |
| M2 | Add GitHub Actions CI with `flutter analyze` + `flutter test` | 3 | ✅ |
| Doc1 | Write full API documentation (dartdoc on all `PlacePicker` parameters) | 5 | ✅ |
| Doc3 | Add migration guide from `google_maps_place_picker` / `google_maps_place_picker_mb` | 3 | ✅ |
| M5 | Add pub.dev publish notes and checklist to README | 3 | ✅ |

---

## 📋 Sprint 3 — Backlog (≤30 SP, not yet scheduled)

| ID | Description | SP |
|----|-------------|-----|
| B10 | Autocomplete overlay offset wrong in some layouts ([upstream #159](https://github.com/fysoul17/google_maps_place_picker/issues/159)) | 3 |
| B11 | `strictbounds` does not correctly filter results ([upstream #155](https://github.com/fysoul17/google_maps_place_picker/issues/155)) | 3 |
| B12 | `region` filter doesn't restrict autocomplete ([upstream #164](https://github.com/fysoul17/google_maps_place_picker/issues/164)) | 3 |
| B13 | `onMapCreated` callback not invoked ([upstream #99](https://github.com/fysoul17/google_maps_place_picker/issues/99)) | 3 |
| B14 | Autocomplete field overlaps results / keyboard ([upstream #154](https://github.com/fysoul17/google_maps_place_picker/issues/154)) | 3 |
| M3 | Unit tests for `PlaceProvider`, `SearchProvider`, `PickResult` | 5 |
| M4 | Widget tests for `AutoCompleteSearch` and `GoogleMapPlacePicker` | 5 |
| M6 | Update `flutter` + all dependencies ([upstream PR #187](https://github.com/fysoul17/google_maps_place_picker/pull/187)) | 3 |
| **Total** | | **28** |

---

## 📋 Sprint 4 — Backlog (not yet scheduled)

| ID | Description | SP |
|----|-------------|-----|
| D5/M1 | Migrate from `flutter_google_maps_webservices` to Places API (New) direct HTTP | 13 |
| B15 | App crash when loading map on some devices ([upstream #96](https://github.com/fysoul17/google_maps_place_picker/issues/96)) | 5 |
| B16 | Inaccurate coordinates in rural areas ([upstream #132](https://github.com/fysoul17/google_maps_place_picker/issues/132)) | 5 |
| **Total** | | **23** |

---

## ✨ Feature Backlog (not yet scheduled — no features in current sprints)

| ID | Description | SP |
|----|-------------|-----|
| F1 | More GoogleMap widget customisation (polylines, polygons) ([upstream #186](https://github.com/fysoul17/google_maps_place_picker/issues/186)) | 5 |
| F2 | Expose `initialCameraPosition` (zoom / bearing) ([upstream #178](https://github.com/fysoul17/google_maps_place_picker/issues/178)) | 3 |
| F3 | Option to disable autocomplete bar ([upstream #171](https://github.com/fysoul17/google_maps_place_picker/issues/171)) | 2 |
| F4 | Customise "Select here" button text — ✅ partially done via `selectText` ([upstream #117](https://github.com/fysoul17/google_maps_place_picker/issues/117)) | 1 |
| F5 | Sort autocomplete by distance (PR [#153](https://github.com/fysoul17/google_maps_place_picker/pull/153)) | 3 |
| F6 | Editable pick-button text/colour + hide bar when unusable (PR [#181](https://github.com/fysoul17/google_maps_place_picker/pull/181)) | 3 |
| F7 | Voice input for search field ([upstream #177](https://github.com/fysoul17/google_maps_place_picker/issues/177)) | 5 |
| F8 | `usePinPointingSearch = false` without losing drag ([upstream #41](https://github.com/fysoul17/google_maps_place_picker/issues/41)) | 3 |
| F9 | Search nearby places ([upstream #135](https://github.com/fysoul17/google_maps_place_picker/issues/135)) | 5 |
| F10 | Search by coordinates ([upstream #83](https://github.com/fysoul17/google_maps_place_picker/issues/83)) | 3 |
| F11 | Web platform support ([upstream #93](https://github.com/fysoul17/google_maps_place_picker/issues/93)) | 8 |
| F12 | Get lat/lng without network call ([upstream #151](https://github.com/fysoul17/google_maps_place_picker/issues/151)) | 2 |
| F13 | Suggestion list inherits app theme ([upstream #97](https://github.com/fysoul17/google_maps_place_picker/issues/97)) | 3 |
| F14 | Expose street number & postal code from geocoding ([upstream #119](https://github.com/fysoul17/google_maps_place_picker/issues/119)) | 2 |

---

## ✅ Already Addressed in this Fork

| ID | Description |
|----|-------------|
| D7 | Replaced `RaisedButton` with `ElevatedButton` (upstream #174, #179, PR #180) |
| D8 | `WidgetsBinding` null-aware warning fixed (upstream #173) |
| D9 | `geolocator` updated to `^14.0.2` (upstream #163, #185) |
| M7 | `permission_handler` replaced with `geolocator` (upstream PR #88) |
| M8 | `package_info_plus` updated to `^9.0.0` (upstream #165) |
