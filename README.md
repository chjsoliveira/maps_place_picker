# maps_place_picker

A Flutter plugin which provides 'Picking Place' using Google Maps widget.

This is an actively maintained fork based on [google_maps_place_picker_mb](https://github.com/chjsoliveira/google_maps_place_picker_mb), which itself is a fork of [google_maps_place_picker](https://github.com/fysoul17/google_maps_place_picker).

## Features

- Pick a place by dragging the map pin (reverse geocoding)
- Pick a place by searching via Google Places Autocomplete
- Customizable UI (pin, floating card, intro modal)
- Restrict picking to a circular area (`pickArea`)
- Zoom controls (cross-platform, including iOS)
- Dark mode support

## Getting started

Add to `pubspec.yaml`:

```yaml
dependencies:
  maps_place_picker:
    git:
      url: https://github.com/chjsoliveira/maps_place_picker
```

## Usage

```dart
import 'package:maps_place_picker/maps_place_picker.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlacePicker(
      apiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
      initialPosition: LatLng(-33.8567844, 151.213108),
      useCurrentLocation: true,
      onPlacePicked: (PickResult result) {
        print(result.formattedAddress);
        Navigator.of(context).pop();
      },
    ),
  ),
);
```

See the `example/` directory for a complete demo application.

---
