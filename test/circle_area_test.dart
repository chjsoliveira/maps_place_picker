import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_place_picker/src/models/circle_area.dart';

void main() {
  group('CircleArea', () {
    test('constructs with required parameters', () {
      const center = LatLng(-23.5505, -46.6333);
      const radius = 500.0;

      final area = CircleArea(center: center, radius: radius);

      expect(area.center, center);
      expect(area.radius, radius);
    });

    test('uses blue fill color with low alpha by default (D1 fix)', () {
      final area = CircleArea(
        center: const LatLng(0, 0),
        radius: 100,
      );

      // fillColor should be a semi-transparent blue (not fully opaque).
      expect(area.fillColor.opacity, lessThan(1.0));
      expect(area.fillColor.blue, greaterThan(0)); // has blue channel
    });

    test('uses blue stroke color with higher alpha than fill by default', () {
      final area = CircleArea(
        center: const LatLng(0, 0),
        radius: 100,
      );

      // strokeColor should be more opaque than fillColor.
      expect(area.strokeColor.opacity, greaterThan(area.fillColor.opacity));
    });

    test('accepts custom fillColor', () {
      const customFill = Colors.red;
      final area = CircleArea(
        center: const LatLng(0, 0),
        radius: 100,
        fillColor: customFill,
      );

      expect(area.fillColor, customFill);
    });

    test('accepts custom strokeColor', () {
      const customStroke = Colors.green;
      final area = CircleArea(
        center: const LatLng(0, 0),
        radius: 100,
        strokeColor: customStroke,
      );

      expect(area.strokeColor, customStroke);
    });

    test('uses strokeWidth of 2 by default', () {
      final area = CircleArea(center: const LatLng(0, 0), radius: 100);
      expect(area.strokeWidth, 2);
    });

    test('accepts custom strokeWidth', () {
      final area = CircleArea(
        center: const LatLng(0, 0),
        radius: 100,
        strokeWidth: 5,
      );
      expect(area.strokeWidth, 5);
    });

    test('each CircleArea has a unique circleId', () {
      final area1 = CircleArea(center: const LatLng(0, 0), radius: 100);
      final area2 = CircleArea(center: const LatLng(0, 0), radius: 100);

      expect(area1.circleId.value, isNot(area2.circleId.value));
    });
  });
}
