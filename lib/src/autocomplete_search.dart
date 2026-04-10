import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maps_place_picker/maps_place_picker.dart';
import 'package:maps_place_picker/providers/place_provider.dart';
import 'package:maps_place_picker/providers/search_provider.dart';
import 'package:maps_place_picker/src/components/prediction_tile.dart';
import 'package:maps_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:maps_place_picker/src/models/prediction.dart';
import 'package:maps_place_picker/src/services/places_service.dart';
import 'package:provider/provider.dart';

/// A search bar widget that fetches and displays autocomplete predictions.
///
/// Connects to [PlaceProvider] and [SearchProvider] via [Provider] to share
/// the current search term and debounce timer.
class AutoCompleteSearch extends StatefulWidget {
  /// Creates an [AutoCompleteSearch].
  const AutoCompleteSearch(
      {super.key,
      required this.sessionToken,
      required this.onPicked,
      required this.appBarKey,
      this.hintText = "Search here",
      this.searchingText = "Searching...",
      this.hidden = false,
      this.height = 46,
      this.contentPadding = EdgeInsets.zero,
      this.debounceMilliseconds,
      this.onSearchFailed,
      required this.searchBarController,
      this.autocompleteOffset,
      this.autocompleteRadius,
      this.autocompleteLanguage,
      this.autocompleteComponents,
      this.autocompleteTypes,
      this.strictbounds,
      this.region,
      this.initialSearchString,
      this.searchForInitialValue,
      this.autocompleteOnTrailingWhitespace,
      this.voiceSearchEnabled = false,
      this.onVoiceSearchTapped});

  /// Session token used to group autocomplete and detail requests for billing.
  final String? sessionToken;

  /// Hint text shown in the empty search field.
  final String? hintText;

  /// Text shown while an autocomplete request is in flight.
  final String? searchingText;

  /// When `true` the search bar is replaced by an empty [Container].
  final bool hidden;

  /// Height of the search bar widget.
  final double height;

  /// Inner padding of the search field.
  final EdgeInsetsGeometry contentPadding;

  /// Debounce delay in milliseconds between keystrokes and API requests.
  final int? debounceMilliseconds;

  /// Called when the user taps a prediction from the overlay list.
  final ValueChanged<Prediction> onPicked;

  /// Called with the API status string when an autocomplete request fails.
  final ValueChanged<String>? onSearchFailed;

  /// Controller that exposes programmatic control over the search bar.
  final SearchBarController searchBarController;

  /// Character offset passed to the autocomplete API.
  final num? autocompleteOffset;

  /// Search radius in metres passed to the autocomplete API.
  final num? autocompleteRadius;

  /// BCP-47 language code for localising autocomplete results.
  final String? autocompleteLanguage;

  /// Place-type filters for the autocomplete request.
  final List<String>? autocompleteTypes;

  /// Country (or other component) filters for the autocomplete request.
  final List<Component>? autocompleteComponents;

  /// When `true`, restricts results to the radius circle.
  final bool? strictbounds;

  /// CLDR two-character region code used to bias autocomplete results.
  final String? region;

  /// Key used to read the [AppBar]'s position for overlay placement.
  final GlobalKey appBarKey;

  /// Initial text pre-filled in the search field.
  final String? initialSearchString;

  /// Whether to immediately search for [initialSearchString] on first render.
  final bool? searchForInitialValue;

  /// Whether to trigger autocomplete when the query ends with a whitespace.
  final bool? autocompleteOnTrailingWhitespace;

  /// Whether to show a microphone button for voice search input.
  ///
  /// When `true`, a mic icon button is displayed after the clear icon.
  /// Tapping it invokes [onVoiceSearchTapped]. The actual speech recognition
  /// is handled by the consumer; feed the result back via
  /// [SearchBarController.setText].
  final bool voiceSearchEnabled;

  /// Called when the microphone button is tapped.
  ///
  /// Only invoked when [voiceSearchEnabled] is `true`.
  final VoidCallback? onVoiceSearchTapped;

  @override
  AutoCompleteSearchState createState() => AutoCompleteSearchState();
}

/// The [State] for [AutoCompleteSearch].
///
/// Exposed as a public class so that [SearchBarController] can call methods on
/// it directly.
class AutoCompleteSearchState extends State<AutoCompleteSearch> {
  /// Controller for the search text field.
  TextEditingController controller = TextEditingController();

  /// Focus node for the search text field.
  FocusNode focus = FocusNode();

  /// The current overlay entry showing predictions or the searching indicator.
  OverlayEntry? overlayEntry;

  /// Local search provider that tracks the current search term.
  SearchProvider provider = SearchProvider();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchString != null) {
      // Add the listener only after setting the initial text so that
      // assigning the pre-fill value does not trigger a debounce timer.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.text = widget.initialSearchString!;
        controller.addListener(_onSearchInputChange);
        if (widget.searchForInitialValue!) {
          _onSearchInputChange();
        }
      });
    } else {
      controller.addListener(_onSearchInputChange);
    }
    focus.addListener(_onFocusChanged);

    widget.searchBarController.attach(this);
  }

  @override
  void dispose() {
    controller.removeListener(_onSearchInputChange);
    controller.dispose();

    focus.removeListener(_onFocusChanged);
    focus.dispose();
    _clearOverlay();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !widget.hidden
        ? ChangeNotifierProvider.value(
            value: provider,
            child: RoundedFrame(
              height: widget.height,
              padding: const EdgeInsets.only(right: 10),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 0,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 10),
                  const Icon(Icons.search),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSearchTextField()),
                  _buildTextClearIcon(),
                  if (widget.voiceSearchEnabled)
                    IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: widget.onVoiceSearchTapped,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          )
        : Container();
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: controller,
      focusNode: focus,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
        errorBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        contentPadding: widget.contentPadding,
      ),
    );
  }

  Widget _buildTextClearIcon() {
    return Selector<SearchProvider, String>(
        selector: (_, provider) => provider.searchTerm,
        builder: (_, data, __) {
          if (data.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                child: Icon(
                  Icons.clear,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                onTap: () {
                  clearText();
                },
              ),
            );
          } else {
            return const SizedBox(width: 10);
          }
        });
  }

  void _onSearchInputChange() {
    if (!mounted) return;
    provider.searchTerm = controller.text;

    PlaceProvider placeProvider = PlaceProvider.of(context, listen: false);

    if (controller.text.isEmpty) {
      placeProvider.debounceTimer?.cancel();
      _searchPlace(controller.text);
      return;
    }

    if (controller.text.trim() == provider.prevSearchTerm.trim()) {
      placeProvider.debounceTimer?.cancel();
      return;
    }

    if (!widget.autocompleteOnTrailingWhitespace! &&
        controller.text.substring(controller.text.length - 1) == " ") {
      placeProvider.debounceTimer?.cancel();
      return;
    }

    if (placeProvider.debounceTimer?.isActive ?? false) {
      placeProvider.debounceTimer!.cancel();
    }

    placeProvider.debounceTimer =
        Timer(Duration(milliseconds: widget.debounceMilliseconds!), () {
      _searchPlace(controller.text.trim());
    });
  }

  void _onFocusChanged() {
    PlaceProvider placeProvider = PlaceProvider.of(context, listen: false);
    placeProvider.isSearchBarFocused = focus.hasFocus;
    placeProvider.debounceTimer?.cancel();
    placeProvider.placeSearchingState = SearchingState.idle;
  }

  void _searchPlace(String searchTerm) {
    provider.prevSearchTerm = searchTerm;

    _clearOverlay();

    if (searchTerm.isEmpty) return;

    _displayOverlay(_buildSearchingOverlay());

    _performAutoCompleteSearch(searchTerm);
  }

  void _clearOverlay() {
    if (overlayEntry != null) {
      try {
        overlayEntry!.remove();
      } catch (_) {}
      overlayEntry = null;
    }
  }

  void _displayOverlay(Widget overlayChild) {
    _clearOverlay();

    final RenderBox? appBarRenderBox =
        widget.appBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (appBarRenderBox == null) return;

    // B10: use localToGlobal for reliable overlay positioning in all layouts.
    final Offset topLeft = appBarRenderBox.localToGlobal(Offset.zero);
    final double overlayTop = topLeft.dy + appBarRenderBox.size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    overlayEntry = OverlayEntry(
      builder: (context) {
        // B14: keep the overlay above the on-screen keyboard.
        final double keyboardHeight =
            MediaQuery.of(context).viewInsets.bottom;
        final double screenHeight = MediaQuery.of(context).size.height;
        // Limit the overlay height so it only takes the space its content
        // needs, while still being scrollable and never exceeding the
        // available space above the keyboard.
        final double maxHeight =
            screenHeight - overlayTop - keyboardHeight - 16;
        return Positioned(
          top: overlayTop,
          left: screenWidth * 0.025,
          right: screenWidth * 0.025,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight.clamp(0, double.infinity)),
            child: Material(
              elevation: 4.0,
              color: Theme.of(context).cardColor,
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!,
                child: SingleChildScrollView(child: overlayChild),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  Widget _buildSearchingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              widget.searchingText ?? "Searching...",
              style: const TextStyle(fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPredictionOverlay(List<Prediction> predictions) {
    return ListBody(
      children: predictions
          .map(
            (p) => PredictionTile(
              prediction: p,
              onTap: (selectedPrediction) {
                resetSearchBar();
                widget.onPicked(selectedPrediction);
              },
            ),
          )
          .toList(),
    );
  }

  Future<void> _performAutoCompleteSearch(String searchTerm) async {
    PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (searchTerm.isNotEmpty) {
      final PlacesAutocompleteResponse response =
          await provider.places.autocomplete(
        searchTerm,
        sessionToken: widget.sessionToken,
        latitude: provider.currentPosition?.latitude,
        longitude: provider.currentPosition?.longitude,
        offset: widget.autocompleteOffset,
        radius: widget.autocompleteRadius,
        language: widget.autocompleteLanguage,
        types: widget.autocompleteTypes ?? const [],
        components: widget.autocompleteComponents ?? const [],
        strictbounds: widget.strictbounds ?? false,
        region: widget.region,
      );

      if (response.errorMessage?.isNotEmpty == true ||
          response.status == "REQUEST_DENIED") {
        if (widget.onSearchFailed != null) {
          widget.onSearchFailed!(response.status);
        }
        return;
      }

      _displayOverlay(_buildPredictionOverlay(response.predictions));
    }
  }

  /// Clears the search field text and resets the search term.
  void clearText() {
    provider.searchTerm = "";
    controller.clear();
  }

  /// Clears the search field and removes focus from the search bar.
  void resetSearchBar() {
    clearText();
    focus.unfocus();
  }

  /// Removes the autocomplete overlay from the screen.
  void clearOverlay() {
    _clearOverlay();
  }
}
