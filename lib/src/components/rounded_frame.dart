import 'package:flutter/material.dart';

/// A container with rounded corners and an optional [Material] elevation.
///
/// Used as the base for [FloatingCard] and the autocomplete search bar.
class RoundedFrame extends StatelessWidget {
  /// Creates a [RoundedFrame].
  const RoundedFrame({
    super.key,
    this.margin,
    this.padding,
    this.width,
    this.height,
    this.child,
    this.color,
    this.borderRadius = BorderRadius.zero,
    this.borderColor = Colors.transparent,
    this.elevation = 0.0,
    this.materialType,
  });

  /// Outer margin around the frame.
  final EdgeInsetsGeometry? margin;

  /// Inner padding between the frame border and [child].
  final EdgeInsetsGeometry? padding;

  /// Fixed width, or `null` to size to content.
  final double? width;

  /// Fixed height, or `null` to size to content.
  final double? height;

  /// Widget rendered inside the frame.
  final Widget? child;

  /// Background colour. When [Colors.transparent], the [Material] type is set
  /// to [MaterialType.transparency].
  final Color? color;

  /// Colour of the rounded border.
  final Color borderColor;

  /// Radius applied to all corners.
  final BorderRadius borderRadius;

  /// Material elevation (shadow depth).
  final double elevation;

  /// Override for the [Material] widget's type. When `null`, defaults to
  /// [MaterialType.canvas] (or [MaterialType.transparency] when [color] is
  /// [Colors.transparent]).
  final MaterialType? materialType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      child: Material(
        type: color == Colors.transparent
            ? MaterialType.transparency
            : materialType ?? MaterialType.canvas,
        color: color,
        shape: RoundedRectangleBorder(
            borderRadius: borderRadius, side: BorderSide(color: borderColor)),
        elevation: elevation,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: child,
        ),
      ),
    );
  }
}
