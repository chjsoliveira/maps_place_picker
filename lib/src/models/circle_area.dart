import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class CircleArea extends Circle {
  CircleArea({
    required LatLng center,
    required double radius,
    Color? fillColor,
    Color? strokeColor,
    int strokeWidth = 2,
  }) : super(
          circleId: CircleId(const Uuid().v4()),
          center: center,
          radius: radius,
          fillColor: fillColor ?? Colors.blue.withValues(alpha: 32 / 255.0),
          strokeColor: strokeColor ?? Colors.blue.withValues(alpha: 192 / 255.0),
          strokeWidth: strokeWidth,
        );
}
