import 'package:flutter_test/flutter_test.dart';
import 'package:maps_place_picker/providers/search_provider.dart';

void main() {
  group('SearchProvider', () {
    test('searchTerm defaults to empty string', () {
      final provider = SearchProvider();
      expect(provider.searchTerm, '');
    });

    test('prevSearchTerm defaults to empty string', () {
      final provider = SearchProvider();
      expect(provider.prevSearchTerm, '');
    });

    test('setting searchTerm notifies listeners', () {
      final provider = SearchProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.searchTerm = 'hello';
      expect(provider.searchTerm, 'hello');
      expect(notifyCount, 1);
    });

    test('setting searchTerm multiple times notifies each time', () {
      final provider = SearchProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.searchTerm = 'a';
      provider.searchTerm = 'ab';
      provider.searchTerm = 'abc';
      expect(notifyCount, 3);
    });

    test('prevSearchTerm can be updated directly', () {
      final provider = SearchProvider();
      provider.prevSearchTerm = 'previous';
      expect(provider.prevSearchTerm, 'previous');
    });
  });
}
