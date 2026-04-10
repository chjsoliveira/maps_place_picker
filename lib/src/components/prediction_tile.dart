import 'package:flutter/material.dart';
import 'package:maps_place_picker/src/models/prediction.dart';

/// A [ListTile] that displays an autocomplete [Prediction] and highlights the
/// portion of the description that matched the user's query.
class PredictionTile extends StatelessWidget {
  /// The autocomplete prediction to display.
  final Prediction prediction;

  /// Called when the user taps the tile.
  final ValueChanged<Prediction>? onTap;

  /// Creates a [PredictionTile] for the given [prediction].
  const PredictionTile({super.key, required this.prediction, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: Text.rich(
        TextSpan(
          children: _buildPredictionText(context),
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap!(prediction);
        }
      },
    );
  }

  List<TextSpan> _buildPredictionText(BuildContext context) {
    final List<TextSpan> result = <TextSpan>[];
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface;

    final description = prediction.description ?? '';

    if (prediction.matchedSubstrings.isNotEmpty) {
      final MatchedSubstring matchedSubString = prediction.matchedSubstrings[0];
      final int offset = matchedSubString.offset;
      final int length = matchedSubString.length;
      final int end = offset + length;

      // Guard against out-of-bounds offsets returned by the API.
      if (offset < 0 || offset > description.length || end > description.length) {
        result.add(
          TextSpan(
            text: description,
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.w300),
          ),
        );
        return result;
      }

      // Text before the match.
      if (offset > 0) {
        result.add(
          TextSpan(
            text: description.substring(0, offset),
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.w300),
          ),
        );
      }

      // Matched text.
      result.add(
        TextSpan(
          text: description.substring(offset, end),
          style: TextStyle(
              color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );

      // Text after the match.
      if (end < description.length) {
        result.add(
          TextSpan(
            text: description.substring(end),
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.w300),
          ),
        );
      }
    } else {
      result.add(
        TextSpan(
          text: description,
          style: TextStyle(
              color: textColor, fontSize: 16, fontWeight: FontWeight.w300),
        ),
      );
    }

    return result;
  }
}
