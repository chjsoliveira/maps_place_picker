import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maps_place_picker/providers/place_provider.dart';
import 'package:maps_place_picker/src/autocomplete_search.dart';
import 'package:maps_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:maps_place_picker/src/google_map_place_picker.dart';
import 'package:maps_place_picker/src/models/geometry.dart';
import 'package:maps_place_picker/src/models/pick_result.dart';
import 'package:maps_place_picker/src/models/prediction.dart';
import 'package:maps_place_picker/src/place_picker.dart';
import 'package:provider/provider.dart';

// ─────────────────────────── helpers ──────────────────────────────────────

http.Client _emptyClient() => MockClient((_) async =>
    http.Response(jsonEncode({'suggestions': []}), 200));

Widget _buildSearchWidget({
  required GlobalKey appBarKey,
  required SearchBarController controller,
  required PlaceProvider placeProvider,
  bool voiceSearchEnabled = false,
  VoidCallback? onVoiceSearchTapped,
  bool hidden = false,
}) {
  return MaterialApp(
    home: ChangeNotifierProvider<PlaceProvider>.value(
      value: placeProvider,
      child: Scaffold(
        appBar: AppBar(key: appBarKey, title: const Text('Test')),
        body: AutoCompleteSearch(
          appBarKey: appBarKey,
          sessionToken: 'tok',
          searchBarController: controller,
          debounceMilliseconds: 0,
          onPicked: (_) {},
          autocompleteOnTrailingWhitespace: false,
          voiceSearchEnabled: voiceSearchEnabled,
          onVoiceSearchTapped: onVoiceSearchTapped,
          hidden: hidden,
        ),
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────

void main() {
  // ── F12 ────────────────────────────────────────────────────────────────
  group('F12 – PickResult geometry-only construction', () {
    test('PickResult can be constructed with only geometry', () {
      final result = PickResult(
        geometry: Geometry(location: Location(lat: 48.8566, lng: 2.3522)),
      );
      expect(result.geometry!.location.lat, 48.8566);
      expect(result.geometry!.location.lng, 2.3522);
      expect(result.placeId, isNull);
      expect(result.formattedAddress, isNull);
    });
  });

  // ── F2 ─────────────────────────────────────────────────────────────────
  group('F2 – PlacePicker initial zoom/tilt/bearing defaults', () {
    test('initialZoom defaults to 15.0', () {
      const picker = PlacePicker(
        apiKey: 'key',
        initialPosition: LatLng(0, 0),
      );
      expect(picker.initialZoom, 15.0);
    });

    test('initialTilt defaults to 0.0', () {
      const picker = PlacePicker(
        apiKey: 'key',
        initialPosition: LatLng(0, 0),
      );
      expect(picker.initialTilt, 0.0);
    });

    test('initialBearing defaults to 0.0', () {
      const picker = PlacePicker(
        apiKey: 'key',
        initialPosition: LatLng(0, 0),
      );
      expect(picker.initialBearing, 0.0);
    });

    test('GoogleMapPlacePicker accepts initialZoom/tilt/bearing', () {
      final key = GlobalKey();
      final picker = GoogleMapPlacePicker(
        initialTarget: const LatLng(0, 0),
        appBarKey: key,
        initialZoom: 12.0,
        initialTilt: 30.0,
        initialBearing: 45.0,
      );
      expect(picker.initialZoom, 12.0);
      expect(picker.initialTilt, 30.0);
      expect(picker.initialBearing, 45.0);
    });
  });

  // ── F4 ─────────────────────────────────────────────────────────────────
  group('F4 – selectedPlaceButtonColor param', () {
    test('PlacePicker.selectedPlaceButtonColor defaults to null', () {
      const picker = PlacePicker(
        apiKey: 'key',
        initialPosition: LatLng(0, 0),
      );
      expect(picker.selectedPlaceButtonColor, isNull);
    });

    test('GoogleMapPlacePicker.selectedPlaceButtonColor can be set', () {
      final key = GlobalKey();
      final picker = GoogleMapPlacePicker(
        initialTarget: const LatLng(0, 0),
        appBarKey: key,
        selectedPlaceButtonColor: Colors.blue,
      );
      expect(picker.selectedPlaceButtonColor, Colors.blue);
    });
  });

  // ── F3 ─────────────────────────────────────────────────────────────────
  group('F3 – showSearchBar param', () {
    test('PlacePicker.showSearchBar defaults to true', () {
      const picker = PlacePicker(
        apiKey: 'key',
        initialPosition: LatLng(0, 0),
      );
      expect(picker.showSearchBar, isTrue);
    });

    testWidgets('AutoCompleteSearch with hidden=true renders no TextField',
        (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyClient(), const {});

      await tester.pumpWidget(_buildSearchWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
        hidden: true,
      ));

      // No TextField when hidden.
      expect(find.byType(TextField), findsNothing);
      provider.dispose();
    });

    testWidgets('AutoCompleteSearch with hidden=false renders TextField',
        (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyClient(), const {});

      await tester.pumpWidget(_buildSearchWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
        hidden: false,
      ));

      expect(find.byType(TextField), findsOneWidget);
      provider.dispose();
    });
  });

  // ── F7 ─────────────────────────────────────────────────────────────────
  group('F7 – SearchBarController.setText', () {
    testWidgets('setText sets the text and cursor at end', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyClient(), const {});

      await tester.pumpWidget(_buildSearchWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      controller.setText('hello world');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller!.text, 'hello world');
      expect(tf.controller!.selection.baseOffset, 11);
      provider.dispose();
    });

    testWidgets('setText with empty string clears the field', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyClient(), const {});

      await tester.pumpWidget(_buildSearchWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      controller.setText('some text');
      await tester.pump();
      controller.setText('');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller!.text, isEmpty);
      provider.dispose();
    });
  });

  // ── F7 – voice search button ────────────────────────────────────────────
  group('F7 – voice search UI', () {
    testWidgets('mic button not shown when voiceSearchEnabled=false',
        (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyClient(), const {});

      await tester.pumpWidget(_buildSearchWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
        voiceSearchEnabled: false,
      ));

      expect(find.byIcon(Icons.mic), findsNothing);
      provider.dispose();
    });

    testWidgets('mic button shown when voiceSearchEnabled=true',
        (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyClient(), const {});

      await tester.pumpWidget(_buildSearchWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
        voiceSearchEnabled: true,
      ));

      expect(find.byIcon(Icons.mic), findsOneWidget);
      provider.dispose();
    });

    testWidgets('tapping mic button invokes onVoiceSearchTapped',
        (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyClient(), const {});
      bool tapped = false;

      await tester.pumpWidget(_buildSearchWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
        voiceSearchEnabled: true,
        onVoiceSearchTapped: () => tapped = true,
      ));

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      expect(tapped, isTrue);
      provider.dispose();
    });
  });

  // ── F1 ─────────────────────────────────────────────────────────────────
  group('F1 – markers/polylines/polygons passthrough', () {
    test('PlacePicker markers/polylines/polygons default to null', () {
      const picker = PlacePicker(
        apiKey: 'key',
        initialPosition: LatLng(0, 0),
      );
      expect(picker.markers, isNull);
      expect(picker.polylines, isNull);
      expect(picker.polygons, isNull);
    });

    test('GoogleMapPlacePicker markers/polylines/polygons default to null', () {
      final key = GlobalKey();
      final picker = GoogleMapPlacePicker(
        initialTarget: const LatLng(0, 0),
        appBarKey: key,
      );
      expect(picker.markers, isNull);
      expect(picker.polylines, isNull);
      expect(picker.polygons, isNull);
    });

    test('GoogleMapPlacePicker accepts non-null markers/polylines/polygons',
        () {
      final markers = <Marker>{
        const Marker(markerId: MarkerId('m1')),
      };
      final polylines = <Polyline>{
        const Polyline(polylineId: PolylineId('p1')),
      };
      final polygons = <Polygon>{
        const Polygon(polygonId: PolygonId('poly1')),
      };

      final picker = GoogleMapPlacePicker(
        initialTarget: const LatLng(0, 0),
        appBarKey: GlobalKey(),
        markers: markers,
        polylines: polylines,
        polygons: polygons,
      );
      expect(picker.markers, markers);
      expect(picker.polylines, polylines);
      expect(picker.polygons, polygons);
    });
  });

  // ── F13 ────────────────────────────────────────────────────────────────
  group('F13 – AutoCompleteSearch theme inheritance', () {
    testWidgets('TextField has bodyMedium style from theme', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyClient(), const {});

      const customTextStyle = TextStyle(fontSize: 20, color: Colors.purple);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(bodyMedium: customTextStyle),
        ),
        home: ChangeNotifierProvider<PlaceProvider>.value(
          value: provider,
          child: Scaffold(
            appBar: AppBar(key: appBarKey),
            body: AutoCompleteSearch(
              appBarKey: appBarKey,
              sessionToken: 'tok',
              searchBarController: controller,
              onPicked: (_) {},
              autocompleteOnTrailingWhitespace: false,
            ),
          ),
        ),
      ));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.style?.fontSize, 20.0);
      provider.dispose();
    });
  });
}
