import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class CircleArea extends Circle {
  CircleArea({
    required super.center,
    required super.radius,
    Color? fillColor,
    Color? strokeColor,
    super.strokeWidth = 2,
  }) : super(
          circleId: CircleId(const Uuid().v4()),
          // Alpha values converted from 0-255 range: 32/255 ≈ 0.125 (semi-transparent fill),
          // 192/255 ≈ 0.753 (mostly opaque stroke). Replaces deprecated withAlpha(int).
          fillColor: fillColor ?? Colors.blue.withValues(alpha: 32 / 255.0),
          strokeColor: strokeColor ?? Colors.blue.withValues(alpha: 192 / 255.0),
        );
}
