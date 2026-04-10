/// A substring in a [Prediction.description] that is highlighted because it
/// matched the user's query.
class MatchedSubstring {
  /// Creates a [MatchedSubstring] with [offset] and [length].
  const MatchedSubstring({required this.offset, required this.length});

  /// Zero-based character offset of the match start.
  final int offset;

  /// Number of characters in the match.
  final int length;

  /// Parses a [MatchedSubstring] from the classic Places API JSON format
  /// (`offset` / `length` keys).
  factory MatchedSubstring.fromJson(Map<String, dynamic> json) =>
      MatchedSubstring(
        offset: json['offset'] as int? ?? 0,
        length: json['length'] as int? ?? 0,
      );

  /// Creates a [MatchedSubstring] from the Places API (New) `matches` format
  /// which uses `startOffset` / `endOffset` instead of `offset` / `length`.
  factory MatchedSubstring.fromNewApiJson(Map<String, dynamic> json) {
    final start = json['startOffset'] as int? ?? 0;
    final end = json['endOffset'] as int? ?? start;
    return MatchedSubstring(offset: start, length: end - start);
  }
}

/// Structured representation of an autocomplete prediction broken into a
/// main text and a secondary text.
class StructuredFormatting {
  /// Creates a [StructuredFormatting] with [mainText] and optional
  /// [secondaryText].
  const StructuredFormatting({
    required this.mainText,
    this.secondaryText,
  });

  /// Primary text of the prediction (usually the place name).
  final String mainText;

  /// Secondary text of the prediction (usually the address or region).
  final String? secondaryText;

  /// Parses a [StructuredFormatting] from the Places API (New) JSON format.
  factory StructuredFormatting.fromNewApiJson(Map<String, dynamic> json) =>
      StructuredFormatting(
        mainText:
            (json['mainText'] as Map<String, dynamic>?)?['text'] as String? ??
                '',
        secondaryText: (json['secondaryText'] as Map<String, dynamic>?)?['text']
            as String?,
      );
}

/// An autocomplete suggestion returned by the Places Autocomplete API.
class Prediction {
  /// Creates a [Prediction] with the given fields.
  const Prediction({
    this.placeId,
    this.description,
    this.matchedSubstrings = const [],
    this.structuredFormatting,
    this.types = const [],
  });

  /// The unique Place ID for this prediction.
  final String? placeId;

  /// Human-readable name of the place, suitable for display.
  final String? description;

  /// Substrings within [description] that match the user's query.
  final List<MatchedSubstring> matchedSubstrings;

  /// Structured breakdown of the prediction text.
  final StructuredFormatting? structuredFormatting;

  /// Place types for this prediction (e.g. `["locality", "geocode"]`).
  final List<String> types;

  /// Parses a `placePrediction` object from the Places API (New) autocomplete
  /// response.
  factory Prediction.fromNewApiJson(Map<String, dynamic> json) {
    final textObj = json['text'] as Map<String, dynamic>?;
    final matches = (textObj?['matches'] as List<dynamic>?)
            ?.map((e) => MatchedSubstring.fromNewApiJson(
                e as Map<String, dynamic>))
            .toList() ??
        const <MatchedSubstring>[];

    final sfObj = json['structuredFormat'] as Map<String, dynamic>?;

    return Prediction(
      placeId: json['placeId'] as String?,
      description: textObj?['text'] as String?,
      matchedSubstrings: matches,
      structuredFormatting: sfObj != null
          ? StructuredFormatting.fromNewApiJson(sfObj)
          : null,
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}
