# Analysis: Vulnerabilities, Bugs & Deprecations

> Package: `maps_place_picker` v3.2.0  
> Based on audit of source ported from `chjsoliveira/google_maps_place_picker_mb@copilot/analyze-complete-solution`

---

## 🔴 Vulnerabilities

### V1 – API Key exposed in app binary (Medium)
**File:** `example/lib/keys.dart`  
**Description:** The Google Maps API key is compiled directly into the application binary. It can be extracted by decompiling the APK/IPA and abused for unauthorized API usage (billing fraud, quota exhaustion).  
**Recommendation:** Restrict the API key in Google Cloud Console (HTTP referrer, Android/iOS app restrictions). Consider using a server-side proxy so the key never ships in the client binary.

### V2 – Unvalidated API response used directly (Low)
**File:** `lib/src/google_map_place_picker.dart`, `lib/src/place_picker.dart`  
**Description:** Geocoding and Places API responses are used without validating the full response contract beyond `errorMessage` and `status`. A malicious or misconfigured proxy could return crafted responses.  
**Recommendation:** Add stricter response validation (null-check `results`, check `geometry` before use).

### V3 – HTTP client passed without TLS verification (Low)
**File:** `lib/providers/place_provider.dart`  
**Description:** A custom `Client` object can be passed in via `httpClient`. There is no enforcement that TLS is enabled, so a developer could accidentally pass an insecure client.  
**Recommendation:** Document that the `httpClient` must use HTTPS. Consider asserting at runtime.

---

## 🟠 Bugs

### B1 – `selectInitialPosition: true` does not work reliably (Confirmed – upstream issue #175)
**File:** `lib/src/google_map_place_picker.dart` → `onMapCreated`  
**Description:** `_searchByCameraLocation` is called inside `onMapCreated` before the camera has fully settled, which can cause the search to use a `null` or default camera position instead of `initialPosition`.  
**Recommendation:** Delay the initial search until `onCameraIdle` fires for the first time (use a `_firstIdle` flag).

### B2 – Infinite loading indicator on iOS autocomplete (Confirmed – upstream issue #68, #78)
**File:** `lib/src/place_picker.dart` → `_pickPrediction`  
**Description:** If an autocomplete prediction is selected but the `getDetailsByPlaceId` call fails silently (no error message but no result), `placeSearchingState` is never reset to `Idle`, leaving the loading indicator spinning forever.  
**Recommendation:** Add a `finally` block that resets `placeSearchingState = SearchingState.Idle`.

### B3 – `RangeError` when selecting address from autocomplete (Confirmed – upstream issue #161)
**File:** `lib/src/components/prediction_tile.dart` → `_buildPredictionText`  
**Description:** `matchedSubString.offset` and `matchedSubString.length` are cast to `int?` then used in `substring`. If the values exceed the description string length, a `RangeError` is thrown.  
**Recommendation:** Add bounds checking before calling `substring`.

### B4 – Search results list not dismissed when tapping "Select here" (Confirmed – upstream issue #57)
**File:** `lib/src/autocomplete_search.dart`  
**Description:** The autocomplete overlay is not cleared when the user taps "Select here" via the default floating card.  
**Recommendation:** Call `searchBarController.clearOverlay()` inside `onPlacePicked`.

### B5 – Camera position used before map is ready (Potential crash)
**File:** `lib/src/google_map_place_picker.dart` → `_searchByCameraLocation`  
**Description:** `provider.cameraPosition` can be `null` and the null check only guards the outer path. If `usePinPointingSearch` is `true` and the user drags before `onMapCreated` completes, a null-dereference can occur.  
**Recommendation:** Guard with an early return if `provider.mapController == null`.

### B6 – Memory leak via `OverlayEntry` on widget disposal
**File:** `lib/src/autocomplete_search.dart` → `dispose`  
**Description:** `_clearOverlay()` is called in `dispose`, but if the `OverlayEntry` is already detached (e.g., parent route popped), calling `remove()` throws an error.  
**Recommendation:** Wrap the `remove()` call in a try/catch or check `overlayEntry!.mounted` before removing.

### B7 – `debounceTimer` not cancelled on `PlaceProvider` disposal
**File:** `lib/providers/place_provider.dart`  
**Description:** `PlaceProvider` does not override `dispose()`. If the widget tree is torn down while a debounce timer is active, the timer fires and attempts to call methods on a disposed provider.  
**Recommendation:** Override `dispose()` to cancel `_debounceTimer`.

---

## 🟡 Deprecations

### D1 – `withAlpha` / `withGreen` color constructors (Flutter ≥3.27)
**Files:** `lib/src/models/circle_area.dart`, `lib/src/place_picker.dart`, `example/lib/main.dart`  
**Description:** `Color.withAlpha(int)`, `Color.withGreen(int)` etc. are deprecated in Flutter 3.27+ in favour of `Color.withValues(alpha: ...)`.  
**Recommendation:** Replace all `withAlpha`, `withRed`, `withGreen`, `withBlue` calls with `withValues(alpha: ...)`.

### D2 – `RawMaterialButton` (Flutter ≥3.19)
**File:** `lib/src/google_map_place_picker.dart` → `_buildMapIcons`  
**Description:** `RawMaterialButton` is deprecated; use `ElevatedButton`, `FilledButton`, or `IconButton` with explicit styling.  
**Recommendation:** Replace with `IconButton.filled` or `ElevatedButton`.

### D3 – `TextTheme.bodyMedium!.color` nullable access pattern
**File:** `lib/src/components/prediction_tile.dart`  
**Description:** Forcing `!` on a nullable `Color?` from `textTheme.bodyMedium` will throw at runtime in strict-null themes.  
**Recommendation:** Use `?? Theme.of(context).colorScheme.onSurface` as a fallback.

### D4 – `new` keyword in example code
**File:** `example/lib/main.dart`  
**Description:** `new CameraPosition(...)` and `new Size(...)` use the deprecated `new` keyword.  
**Recommendation:** Remove `new` keyword throughout.

### D5 – `package_info_plus` version constraint
**File:** `pubspec.yaml`  
**Description:** The `package_info_plus: ^9.0.0` dependency is very recent and may require updating consuming apps' minimum SDK.  
**Recommendation:** Document the minimum Flutter/Dart SDK requirements explicitly.

### D6 – `EagerGestureRecognizer` still required workaround
**File:** `lib/src/google_map_place_picker.dart`  
**Description:** Using `EagerGestureRecognizer` as a gesture recognizer for `GoogleMap` is a known workaround for nested scroll views. Newer versions of `google_maps_flutter` may have resolved this natively.  
**Recommendation:** Test whether the workaround is still necessary on `google_maps_flutter ^2.12.1` and remove if not needed.

### D7 – `flutter_google_maps_webservices` package (unmaintained)
**File:** `pubspec.yaml`  
**Description:** `flutter_google_maps_webservices ^1.1.1` is based on an old fork of `google_maps_webservices`. The upstream package is effectively unmaintained and the Places API v1 (new) is not supported.  
**Recommendation:** Migrate to direct HTTP calls to the [Places API (New)](https://developers.google.com/maps/documentation/places/web-service/overview) or use `dart_google_maps_core`.
