import 'package:flutter/material.dart';

/// A widget that animates its [child] up and down in a looping bounce.
///
/// Used as the default map pin to indicate that the camera is in motion.
class AnimatedPin extends StatefulWidget {
  /// Creates an [AnimatedPin] that bounces [child] continuously.
  const AnimatedPin({
    super.key,
    this.child,
  });

  /// The widget to animate.
  final Widget? child;

  @override
  State<AnimatedPin> createState() => _AnimatedPinState();
}

class _AnimatedPinState extends State<AnimatedPin>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JumpingContainer(controller: _controller, child: widget.child);
  }
}

/// An [AnimatedWidget] that translates its [child] vertically according to
/// [controller]'s value, producing a "jumping" effect.
class JumpingContainer extends AnimatedWidget {
  /// Creates a [JumpingContainer] driven by [controller].
  const JumpingContainer({
    super.key,
    required AnimationController controller,
    this.child,
  }) : super(listenable: controller);

  /// The widget to translate.
  final Widget? child;

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -10 + _progress.value * 10),
      child: child,
    );
  }
}
