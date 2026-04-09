import 'package:flutter_test/flutter_test.dart';
import 'package:maps_place_picker/src/models/component.dart';
import 'package:maps_place_picker/src/models/geometry.dart';

void main() {
  group('Component', () {
    test('Component.country is the string "country"', () {
      expect(Component.country, 'country');
    });

    test('constructs with component and value', () {
      const c = Component(Component.country, 'us');
      expect(c.component, 'country');
      expect(c.value, 'us');
    });

    test('constructs with custom component type', () {
      const c = Component('region', 'eu');
      expect(c.component, 'region');
      expect(c.value, 'eu');
    });
  });

  group('Bounds', () {
    test('fromJson parses northeast and southwest', () {
      final bounds = Bounds.fromJson({
        'northeast': {'lat': 10.1, 'lng': 20.1},
        'southwest': {'lat': 9.9, 'lng': 19.9},
      });

      expect(bounds.northeast.lat, 10.1);
      expect(bounds.northeast.lng, 20.1);
      expect(bounds.southwest.lat, 9.9);
      expect(bounds.southwest.lng, 19.9);
    });
  });

  group('Component – country codes', () {
    test('constructs components with country codes and verifies field equality', () {
      // Component with a Brazil country code:
      const br = Component(Component.country, 'br');
      expect(br.value, 'br');

      // Two components with the same type and value have equal fields:
      const us1 = Component(Component.country, 'us');
      const us2 = Component(Component.country, 'us');
      expect(us1.component, us2.component);
      expect(us1.value, us2.value);
    });
  });
}
