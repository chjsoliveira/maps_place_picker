import 'package:flutter/cupertino.dart';
import 'package:maps_place_picker/src/autocomplete_search.dart';

/// Programmatic controller for [AutoCompleteSearch].
///
/// Attach to an [AutoCompleteSearchState] via [attach] and use [clear],
/// [reset], [clearOverlay], and [setText] to manipulate the search bar
/// from outside the widget tree (e.g. from [PlacePicker]).
class SearchBarController extends ChangeNotifier {
  late AutoCompleteSearchState _autoCompleteSearch;

  /// Attaches this controller to the given [AutoCompleteSearchState].
  ///
  /// Must be called before any other method.
  void attach(AutoCompleteSearchState searchWidget) {
    _autoCompleteSearch = searchWidget;
  }

  /// Just clears text.
  void clear() {
    _autoCompleteSearch.clearText();
  }

  /// Clear and remove focus (Dismiss keyboard)
  void reset() {
    _autoCompleteSearch.resetSearchBar();
  }

  /// Closes the autocomplete overlay without clearing the search text.
  void clearOverlay() {
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
