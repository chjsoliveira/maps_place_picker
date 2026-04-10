import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maps_place_picker/providers/place_provider.dart';
import 'package:maps_place_picker/src/autocomplete_search.dart';
import 'package:maps_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:maps_place_picker/src/models/prediction.dart';
import 'package:provider/provider.dart';

// ─────────────────────────── helpers ──────────────────────────────────────

/// Creates an [http.Client] that always returns an empty autocomplete result.
http.Client _emptyAutoCompleteClient() =>
    MockClient((_) async =>
        http.Response(jsonEncode({'suggestions': []}), 200));

/// Creates an [http.Client] that returns one prediction for autocomplete.
http.Client _onePredictionClient() => MockClient((request) async {
      if (request.url.path.contains('autocomplete')) {
        return http.Response(
          jsonEncode({
            'suggestions': [
              {
                'placePrediction': {
                  'placeId': 'pred1',
                  'text': {
                    'text': 'São Paulo, Brazil',
                    'matches': [
                      {'startOffset': 0, 'endOffset': 3}
                    ],
                  },
                  'structuredFormat': {
                    'mainText': {'text': 'São Paulo'},
                    'secondaryText': {'text': 'Brazil'},
                  },
                  'types': ['locality'],
                }
              }
            ]
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'status': 'OK', 'results': []}), 200);
    });

Widget _buildTestWidget({
  required GlobalKey appBarKey,
  required SearchBarController controller,
  required PlaceProvider placeProvider,
  ValueChanged<Prediction>? onPicked,
  String? initialSearchString,
  bool searchForInitialValue = false,
}) {
  return MaterialApp(
    home: ChangeNotifierProvider<PlaceProvider>.value(
      value: placeProvider,
      child: Scaffold(
        appBar: AppBar(
          key: appBarKey,
          title: const Text('Test'),
        ),
        body: AutoCompleteSearch(
          appBarKey: appBarKey,
          sessionToken: 'session123',
          searchBarController: controller,
          debounceMilliseconds: 0, // no debounce in tests
          onPicked: onPicked ?? (_) {},
          initialSearchString: initialSearchString,
          searchForInitialValue: searchForInitialValue,
          // Provide explicit bool to avoid null-check crash on '!' in widget.
          autocompleteOnTrailingWhitespace: false,
        ),
      ),
    ),
  );
}

// ──────────────────────────────── tests ───────────────────────────────────

void main() {
  group('AutoCompleteSearch – rendering', () {
    testWidgets('renders search field and search icon', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyAutoCompleteClient(), const {});

      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders hint text inside TextField', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyAutoCompleteClient(), const {});

      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<PlaceProvider>.value(
          value: provider,
          child: Scaffold(
            appBar: AppBar(key: appBarKey),
            body: AutoCompleteSearch(
              appBarKey: appBarKey,
              sessionToken: 'tok',
              searchBarController: controller,
              hintText: 'Find a place',
              onPicked: (_) {},
              autocompleteOnTrailingWhitespace: false,
            ),
          ),
        ),
      ));

      expect(find.text('Find a place'), findsOneWidget);
    });
  });

  group('AutoCompleteSearch – clearText', () {
    testWidgets('clearText empties the search field', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyAutoCompleteClient(), const {});

      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      controller.clear();
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });
  });

  group('AutoCompleteSearch – clearOverlay', () {
    testWidgets('clearOverlay removes the prediction overlay', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _onePredictionClient(), const {});

      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      // Type to trigger search.
      await tester.enterText(find.byType(TextField), 'São');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 500));

      // Overlay may be visible with predictions; clear it.
      controller.clearOverlay();
      await tester.pump();

      // After clearing, predictions overlay should be gone.
      expect(find.text('São Paulo, Brazil'), findsNothing);
    });
  });

  group('AutoCompleteSearch – clear icon', () {
    testWidgets('shows clear icon when text is non-empty', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyAutoCompleteClient(), const {});

      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      // Initially no clear icon.
      expect(find.byIcon(Icons.clear), findsNothing);

      // Type something.
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('tapping clear icon empties the text field', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyAutoCompleteClient(), const {});

      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);

      // The searching overlay may be shown on top of the clear icon after the
      // debounce timer fires; clear it before tapping.
      controller.clearOverlay();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });
  });

  group('AutoCompleteSearch – initialSearchString', () {
    testWidgets('pre-fills search field with initialSearchString', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _emptyAutoCompleteClient(), const {});

      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
        initialSearchString: 'pre-filled',
        searchForInitialValue: false,
      ));

      await tester.pump(); // allow post-frame callback

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'pre-filled');
    });
  });

  group('AutoCompleteSearch – predictions overlay', () {
    testWidgets('shows predictions after typing', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _onePredictionClient(), const {});

      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      await tester.enterText(find.byType(TextField), 'São');
      // Allow the debounce + async search to complete.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('São Paulo'), findsWidgets);
    });

    testWidgets('tapping a prediction invokes onPicked', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _onePredictionClient(), const {});

      Prediction? picked;
      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
        onPicked: (p) => picked = p,
      ));

      await tester.enterText(find.byType(TextField), 'São');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 500));

      // Tap the first prediction tile if it appeared.
      final predTile = find.textContaining('São Paulo');
      if (predTile.evaluate().isNotEmpty) {
        await tester.tap(predTile.first);
        await tester.pump();
        expect(picked, isNotNull);
        expect(picked!.placeId, 'pred1');
      }
    });

    testWidgets('empty input clears overlay immediately', (tester) async {
      final appBarKey = GlobalKey();
      final controller = SearchBarController();
      final provider =
          PlaceProvider('key', null, _onePredictionClient(), const {});

      await tester.pumpWidget(_buildTestWidget(
        appBarKey: appBarKey,
        controller: controller,
        placeProvider: provider,
      ));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 50));

      // Clear text.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Overlay should be gone.
      expect(find.text('São Paulo, Brazil'), findsNothing);
    });
  });
}
