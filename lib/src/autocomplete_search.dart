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

class AutoCompleteSearch extends StatefulWidget {
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
      this.autocompleteOnTrailingWhitespace});

  final String? sessionToken;
  final String? hintText;
  final String? searchingText;
  final bool hidden;
  final double height;
  final EdgeInsetsGeometry contentPadding;
  final int? debounceMilliseconds;
  final ValueChanged<Prediction> onPicked;
  final ValueChanged<String>? onSearchFailed;
  final SearchBarController searchBarController;
  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictbounds;
  final String? region;
  final GlobalKey appBarKey;
  final String? initialSearchString;
  final bool? searchForInitialValue;
  final bool? autocompleteOnTrailingWhitespace;

  @override
  AutoCompleteSearchState createState() => AutoCompleteSearchState();
}

class AutoCompleteSearchState extends State<AutoCompleteSearch> {
  TextEditingController controller = TextEditingController();
  FocusNode focus = FocusNode();
  OverlayEntry? overlayEntry;
  SearchProvider provider = SearchProvider();

  @override
  void initState() {
    super.initState();
    controller.addListener(_onSearchInputChange);
    if (widget.initialSearchString != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Remove the listener temporarily to avoid triggering a debounce
        // timer when pre-filling the text field.
        controller.removeListener(_onSearchInputChange);
        controller.text = widget.initialSearchString!;
        controller.addListener(_onSearchInputChange);
        if (widget.searchForInitialValue!) {
          _onSearchInputChange();
        }
      });
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

  _onSearchInputChange() {
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

  _onFocusChanged() {
    PlaceProvider placeProvider = PlaceProvider.of(context, listen: false);
    placeProvider.isSearchBarFocused = focus.hasFocus;
    placeProvider.debounceTimer?.cancel();
    placeProvider.placeSearchingState = SearchingState.idle;
  }

  _searchPlace(String searchTerm) {
    provider.prevSearchTerm = searchTerm;

    _clearOverlay();

    if (searchTerm.isEmpty) return;

    _displayOverlay(_buildSearchingOverlay());

    _performAutoCompleteSearch(searchTerm);
  }

  _clearOverlay() {
    if (overlayEntry != null) {
      try {
        overlayEntry!.remove();
      } catch (_) {}
      overlayEntry = null;
    }
  }

  _displayOverlay(Widget overlayChild) {
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
        return Positioned(
          top: overlayTop,
          left: screenWidth * 0.025,
          right: screenWidth * 0.025,
          bottom: keyboardHeight,
          child: Material(
            elevation: 4.0,
            child: SingleChildScrollView(child: overlayChild),
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

  _performAutoCompleteSearch(String searchTerm) async {
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

  clearText() {
    provider.searchTerm = "";
    controller.clear();
  }

  resetSearchBar() {
    clearText();
    focus.unfocus();
  }

  clearOverlay() {
    _clearOverlay();
  }
}
