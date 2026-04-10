/// A Google Maps place-picker widget for Flutter.
///
/// Provides [PlacePicker], a full-screen widget that lets users search for and
/// select a location using the Google Maps Places API (New) and Geocoding API.
///
/// **Quick start:**
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => PlacePicker(
///       apiKey: 'YOUR_API_KEY',
///       initialPosition: LatLng(-23.5505, -46.6333),
///       onPlacePicked: (result) => print(result.formattedAddress),
///     ),
///   ),
/// );
/// ```

export 'src/models/pick_result.dart';
export 'src/models/component.dart';
export 'src/components/floating_card.dart';
export 'src/components/rounded_frame.dart';
export 'src/models/circle_area.dart';
export 'src/place_picker.dart';
