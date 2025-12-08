import 'package:flutter/material.dart';

/// Direction for the slide animation
enum SlideDirection {
  /// Slides up when hiding (for headers)
  up,

  /// Slides down when hiding (for bottom navigation)
  down,
}

/// A widget that wraps content and animates its visibility with a slide transition.
///
/// Use this with [HideOnScrollMixin] to create hide-on-scroll effects for
/// headers and bottom navigation bars.
///
/// Example:
/// ```dart
/// AnimatedVisibilityWrapper(
///   isVisible: isHeaderVisible,
///   direction: SlideDirection.up,
///   child: MyHeader(),
/// )
/// ```
class AnimatedVisibilityWrapper extends StatefulWidget {
  /// The child widget to show/hide
  final Widget child;

  /// Whether the child should be visible
  final bool isVisible;

  /// The direction to slide when hiding
  final SlideDirection direction;

  /// Animation duration (default: 200ms)
  final Duration duration;

  /// Animation curve (default: easeInOut)
  final Curve curve;

  /// Whether to maintain the child's state when hidden
  final bool maintainState;

  /// Whether to maintain the child's size when hidden (prevents layout jumps)
  final bool maintainSize;

  const AnimatedVisibilityWrapper({
    super.key,
    required this.child,
    required this.isVisible,
    this.direction = SlideDirection.up,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.maintainState = true,
    this.maintainSize = false,
  });

  @override
  State<AnimatedVisibilityWrapper> createState() =>
      _AnimatedVisibilityWrapperState();
}

class _AnimatedVisibilityWrapperState extends State<AnimatedVisibilityWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
      value: widget.isVisible ? 1.0 : 0.0,
    );
    _setupAnimation();
  }

  void _setupAnimation() {
    final beginOffset = widget.direction == SlideDirection.up
        ? const Offset(0, -1)
        : const Offset(0, 1);

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didUpdateWidget(AnimatedVisibilityWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.direction != oldWidget.direction) {
      _setupAnimation();
    }

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // When fully hidden, optionally don't render at all
        if (_controller.value == 0 && !widget.maintainSize) {
          return const SizedBox.shrink();
        }

        return ClipRect(
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
