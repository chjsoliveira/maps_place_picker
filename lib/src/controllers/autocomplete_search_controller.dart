import 'package:flutter/cupertino.dart';
import 'package:maps_place_picker/src/autocomplete_search.dart';

class SearchBarController extends ChangeNotifier {
  late AutoCompleteSearchState _autoCompleteSearch;

  attach(AutoCompleteSearchState searchWidget) {
    _autoCompleteSearch = searchWidget;
  }

  /// Just clears text.
  clear() {
    _autoCompleteSearch.clearText();
  }

  /// Clear and remove focus (Dismiss keyboard)
  reset() {
    _autoCompleteSearch.resetSearchBar();
  }

  clearOverlay() {
    _autoCompleteSearch.clearOverlay();
  }

  /// Programmatically sets the search text (e.g. from a voice recognition
  /// result).
  ///
  /// The cursor is positioned at the end of [text].
  void setText(String text) {
    _autoCompleteSearch.controller.text = text;
    _autoCompleteSearch.controller.selection =
        TextSelection.collapsed(offset: text.length);
  }
}
