import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Lightweight provider that tracks the text currently entered in the
/// autocomplete search bar.
class SearchProvider extends ChangeNotifier {
  /// Returns the nearest [SearchProvider] ancestor from [context].
  static SearchProvider of(BuildContext context, {bool listen = true}) =>
      Provider.of<SearchProvider>(context, listen: listen);

  /// The search term that was active during the previous search, used to avoid
  /// redundant API calls when the text has not changed.
  String prevSearchTerm = "";

  String _searchTerm = "";

  /// The text currently entered in the search bar.
  String get searchTerm => _searchTerm;

  /// Updates [searchTerm] and notifies listeners.
  set searchTerm(String newValue) {
    _searchTerm = newValue;
    notifyListeners();
  }
}
