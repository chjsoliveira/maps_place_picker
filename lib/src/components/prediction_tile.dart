import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';

class PredictionTile extends StatelessWidget {
  final Prediction prediction;
  final ValueChanged<Prediction>? onTap;

  PredictionTile({required this.prediction, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.location_on),
      title: RichText(
        text: TextSpan(
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
      final int offset = matchedSubString.offset as int;
      final int length = matchedSubString.length as int;
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
