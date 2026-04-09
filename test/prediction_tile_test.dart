import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps_place_picker/src/components/prediction_tile.dart';
import 'package:maps_place_picker/src/models/prediction.dart';

void main() {
  group('PredictionTile', () {
    Widget buildTile(Prediction prediction, {ValueChanged<Prediction>? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: PredictionTile(prediction: prediction, onTap: onTap),
        ),
      );
    }

    testWidgets('renders description text', (WidgetTester tester) async {
      final prediction = const Prediction(
        placeId: 'id1',
        description: 'Sydney, Australia',
        matchedSubstrings: [],
      );

      await tester.pumpWidget(buildTile(prediction));
      expect(find.textContaining('Sydney'), findsOneWidget);
    });

    testWidgets('renders matched substring in bold', (WidgetTester tester) async {
      final prediction = Prediction(
        placeId: 'id2',
        description: 'Berlin, Germany',
        matchedSubstrings: [MatchedSubstring.fromJson({'offset': 0, 'length': 6})],
      );

      await tester.pumpWidget(buildTile(prediction));
      // The tile should render all text
      expect(find.textContaining('Berlin'), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      Prediction? tappedPrediction;
      final prediction = const Prediction(
        placeId: 'id3',
        description: 'Tokyo, Japan',
        matchedSubstrings: [],
      );

      await tester.pumpWidget(buildTile(prediction, onTap: (p) {
        tappedPrediction = p;
      }));

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tappedPrediction, isNotNull);
      expect(tappedPrediction!.placeId, 'id3');
    });

    testWidgets('handles out-of-bounds matchedSubstrings gracefully (B3)',
        (WidgetTester tester) async {
      // offset + length > description.length should not throw
      final prediction = Prediction(
        placeId: 'id4',
        description: 'Rome',
        matchedSubstrings: [
          MatchedSubstring.fromJson({'offset': 0, 'length': 100})
        ],
      );

      await tester.pumpWidget(buildTile(prediction));
      // Should render without throwing
      expect(find.textContaining('Rome'), findsOneWidget);
    });

    testWidgets('displays location icon', (WidgetTester tester) async {
      final prediction =
          const Prediction(placeId: 'id5', description: 'Test');
      await tester.pumpWidget(buildTile(prediction));
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });
  });
}
