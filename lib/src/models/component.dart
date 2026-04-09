/// A filter component that can be passed to [PlacePicker.autocompleteComponents]
/// to restrict or bias autocomplete results.
///
/// Currently the only supported component type is [country].
///
/// Example:
/// ```dart
/// autocompleteComponents: [Component(Component.country, 'us')]
/// ```
class Component {
  /// Restricts results to a specific country using its two-letter ISO 3166-1
  /// alpha-2 code (e.g. `"us"`, `"br"`, `"de"`).
  static const String country = 'country';

  const Component(this.component, this.value);

  /// The component type (currently only [country] is supported).
  final String component;

  /// The value for the component (e.g. `"us"` for the United States).
  final String value;
}
