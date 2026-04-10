import 'package:flutter/material.dart';
import 'package:maps_place_picker/src/components/rounded_frame.dart';

/// A positioned card that floats over the map at a specified location.
///
/// Wraps [RoundedFrame] inside a [Positioned] widget so that it can be placed
/// at an exact offset within a [Stack].
class FloatingCard extends StatelessWidget {
  /// Creates a [FloatingCard] at the given position within a [Stack].
  const FloatingCard({
    super.key,
    this.topPosition,
    this.leftPosition,
    this.rightPosition,
    this.bottomPosition,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.elevation = 0.0,
    this.color,
    this.child,
  });

  /// Distance from the top edge of the [Stack].
  final double? topPosition;

  /// Distance from the left edge of the [Stack].
  final double? leftPosition;

  /// Distance from the bottom edge of the [Stack].
  final double? bottomPosition;

  /// Distance from the right edge of the [Stack].
  final double? rightPosition;

  /// Fixed width of the card, or `null` to size to content.
  final double? width;

  /// Fixed height of the card, or `null` to size to content.
  final double? height;

  /// Border radius applied to all corners of the card.
  final BorderRadius borderRadius;

  /// Material elevation of the card.
  final double elevation;

  /// Background colour of the card, or `null` for the default canvas colour.
  final Color? color;

  /// Widget rendered inside the card.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topPosition,
      left: leftPosition,
      right: rightPosition,
      bottom: bottomPosition,
      child: RoundedFrame(
        width: width,
        height: height,
        borderRadius: borderRadius,
        elevation: elevation,
        color: color,
        child: child,
      ),
    );
  }
}
