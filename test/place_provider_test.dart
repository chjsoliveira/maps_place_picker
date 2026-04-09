import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_place_picker/providers/place_provider.dart';
import 'package:maps_place_picker/src/place_picker.dart';
import 'package:maps_place_picker/src/models/pick_result.dart';
import 'package:maps_place_picker/src/models/geometry.dart';

void main() {
  group('PlaceProvider – initial state', () {
    late PlaceProvider provider;

    setUp(() {
      provider = PlaceProvider('test_key', null, null, const {});
    });

    tearDown(() => provider.dispose());

    test('sessionToken defaults to null', () {
      expect(provider.sessionToken, isNull);
    });

    test('isOnUpdateLocationCooldown defaults to false', () {
      expect(provider.isOnUpdateLocationCooldown, isFalse);
    });

    test('isAutoCompleteSearching defaults to false', () {
      expect(provider.isAutoCompleteSearching, isFalse);
    });

    test('currentPosition defaults to null', () {
      expect(provider.currentPosition, isNull);
    });

    test('debounceTimer defaults to null', () {
      expect(provider.debounceTimer, isNull);
    });

    test('prevCameraPosition defaults to null', () {
      expect(provider.prevCameraPosition, isNull);
    });

    test('cameraPosition defaults to null', () {
      expect(provider.cameraPosition, isNull);
    });

    test('selectedPlace defaults to null', () {
      expect(provider.selectedPlace, isNull);
    });

    test('placeSearchingState defaults to Idle', () {
      expect(provider.placeSearchingState, SearchingState.idle);
    });

    test('mapController defaults to null', () {
      expect(provider.mapController, isNull);
    });

    test('pinState defaults to Preparing', () {
      expect(provider.pinState, PinState.preparing);
    });

    test('isSearchBarFocused defaults to false', () {
      expect(provider.isSearchBarFocused, isFalse);
    });

    test('mapType defaults to normal', () {
      expect(provider.mapType, MapType.normal);
    });

    test('pendingInitialSearch defaults to false', () {
      expect(provider.pendingInitialSearch, isFalse);
    });
  });

  group('PlaceProvider – state notifications', () {
    late PlaceProvider provider;
    late List<String> notifiedProperties;

    setUp(() {
      provider = PlaceProvider('test_key', null, null, const {});
      notifiedProperties = [];
    });

    tearDown(() => provider.dispose());

    test('setting placeSearchingState notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.placeSearchingState = SearchingState.searching;
      expect(notifyCount, 1);
      expect(provider.placeSearchingState, SearchingState.searching);

      provider.placeSearchingState = SearchingState.idle;
      expect(notifyCount, 2);
    });

    test('setting pinState notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.pinState = PinState.dragging;
      expect(notifyCount, 1);
      expect(provider.pinState, PinState.dragging);
    });

    test('setting mapController notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.mapController = null; // setting to null still notifies
      expect(notifyCount, 1);
    });

    test('setting selectedPlace notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      final place = PickResult(
        placeId: 'p1',
        geometry: Geometry(location: Location(lat: 1.0, lng: 2.0)),
        formattedAddress: 'Test Address',
      );

      provider.selectedPlace = place;
      expect(notifyCount, 1);
      expect(provider.selectedPlace, same(place));
    });

    test('setting isSearchBarFocused notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.isSearchBarFocused = true;
      expect(notifyCount, 1);
      expect(provider.isSearchBarFocused, isTrue);
    });

    test('setting debounceTimer notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      final timer = Timer(const Duration(seconds: 10), () {});
      provider.debounceTimer = timer;
      expect(notifyCount, 1);
      timer.cancel();
    });
  });

  group('PlaceProvider – camera position (no notification)', () {
    late PlaceProvider provider;

    setUp(() {
      provider = PlaceProvider('test_key', null, null, const {});
    });

    tearDown(() => provider.dispose());

    test('setCameraPosition stores position without notifying', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      const pos = CameraPosition(target: LatLng(10.0, 20.0), zoom: 15.0);
      provider.setCameraPosition(pos);

      expect(notifyCount, 0); // no notification
      expect(provider.cameraPosition, pos);
    });

    test('setPrevCameraPosition stores position without notifying', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      const pos = CameraPosition(target: LatLng(5.0, 6.0), zoom: 12.0);
      provider.setPrevCameraPosition(pos);

      expect(notifyCount, 0); // no notification
      expect(provider.prevCameraPosition, pos);
    });

    test('setCameraPosition can be set to null', () {
      const pos = CameraPosition(target: LatLng(1.0, 1.0), zoom: 10.0);
      provider.setCameraPosition(pos);
      provider.setCameraPosition(null);
      expect(provider.cameraPosition, isNull);
    });
  });

  group('PlaceProvider – MapType', () {
    late PlaceProvider provider;

    setUp(() {
      provider = PlaceProvider('test_key', null, null, const {});
    });

    tearDown(() => provider.dispose());

    test('setMapType changes mapType without notifying by default', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setMapType(MapType.satellite);
      expect(provider.mapType, MapType.satellite);
      expect(notifyCount, 0);
    });

    test('setMapType with notify:true notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setMapType(MapType.terrain, notify: true);
      expect(provider.mapType, MapType.terrain);
      expect(notifyCount, 1);
    });

    test('switchMapType cycles through map types', () {
      provider.setMapType(MapType.normal);
      provider.switchMapType();
      expect(provider.mapType, isNot(MapType.normal));
    });

    test('switchMapType skips MapType.none', () {
      // Force through all types; none should never appear.
      for (int i = 0; i < MapType.values.length * 2; i++) {
        provider.switchMapType();
        expect(provider.mapType, isNot(MapType.none));
      }
    });

    test('switchMapType notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.switchMapType();
      expect(notifyCount, 1);
    });
  });

  group('PlaceProvider – dispose cancels debounce timer (B7)', () {
    test('dispose cancels active debounce timer', () async {
      final provider = PlaceProvider('test_key', null, null, const {});
      bool timerFired = false;

      final timer = Timer(const Duration(milliseconds: 100), () {
        timerFired = true;
      });
      provider.debounceTimer = timer;

      // dispose() must cancel the timer before it fires.
      provider.dispose();

      // Wait longer than the timer duration to confirm it did not fire.
      await Future.delayed(const Duration(milliseconds: 200));
      expect(timerFired, isFalse);
    });

    test('dispose with no timer does not throw', () {
      final provider = PlaceProvider('test_key', null, null, const {});
      expect(provider.debounceTimer, isNull);
      expect(() => provider.dispose(), returnsNormally);
    });
  });

  group('PlaceProvider – pendingInitialSearch', () {
    late PlaceProvider provider;

    setUp(() {
      provider = PlaceProvider('test_key', null, null, const {});
    });

    tearDown(() => provider.dispose());

    test('pendingInitialSearch can be set to true', () {
      provider.pendingInitialSearch = true;
      expect(provider.pendingInitialSearch, isTrue);
    });

    test('pendingInitialSearch can be reset to false', () {
      provider.pendingInitialSearch = true;
      provider.pendingInitialSearch = false;
      expect(provider.pendingInitialSearch, isFalse);
    });
  });
}
