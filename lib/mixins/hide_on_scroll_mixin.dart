import 'package:flutter/material.dart';

/// Mixin that provides hide-on-scroll functionality for headers and bottom navigation.
///
/// Usage:
/// 1. Add the mixin to your State class: `with HideOnScrollMixin`
/// 2. Call `initHideOnScroll()` in `initState()`
/// 3. Call `disposeHideOnScroll()` in `dispose()`
/// 4. Pass `hideOnScrollController` to your scrollable widget
/// 5. Use `isHeaderVisible` and `isBottomNavVisible` to control visibility
///
/// Example:
/// ```dart
/// class _MyPageState extends State<MyPage> with HideOnScrollMixin {
///   @override
///   void initState() {
///     super.initState();
///     initHideOnScroll();
///   }
///
///   @override
///   void dispose() {
///     disposeHideOnScroll();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Column(
///         children: [
///           AnimatedVisibilityWrapper(
///             isVisible: isHeaderVisible,
///             direction: SlideDirection.up,
///             child: MyHeader(),
///           ),
///           Expanded(
///             child: ListView.builder(
///               controller: hideOnScrollController,
///               // ...
///             ),
///           ),
///         ],
///       ),
///       bottomNavigationBar: AnimatedVisibilityWrapper(
///         isVisible: isBottomNavVisible,
///         direction: SlideDirection.down,
///         child: MyBottomNav(),
///       ),
///     );
///   }
/// }
/// ```
mixin HideOnScrollMixin<T extends StatefulWidget> on State<T> {
  /// The scroll controller to attach to your scrollable widget
  late ScrollController hideOnScrollController;

  /// Whether the header should be visible
  bool isHeaderVisible = true;

  /// Whether the bottom navigation should be visible
  bool isBottomNavVisible = true;

  /// Last recorded scroll offset for direction detection
  double _lastScrollOffset = 0;

  /// Minimum scroll delta to trigger visibility change (prevents jitter)
  static const double _scrollThreshold = 15.0;

  /// Accumulated scroll delta since last visibility change
  double _accumulatedDelta = 0;

  /// Whether we own the scroll controller (and should dispose it)
  bool _ownsScrollController = false;

  /// Initialize the hide-on-scroll functionality
  /// Call this in your initState()
  void initHideOnScroll({ScrollController? existingController}) {
    if (existingController != null) {
      hideOnScrollController = existingController;
      _ownsScrollController = false;
    } else {
      hideOnScrollController = ScrollController();
      _ownsScrollController = true;
    }
    hideOnScrollController.addListener(_handleScroll);
  }

  /// Dispose the hide-on-scroll functionality
  /// Call this in your dispose()
  void disposeHideOnScroll() {
    hideOnScrollController.removeListener(_handleScroll);
    // Only dispose if we created the controller
    if (_ownsScrollController) {
      hideOnScrollController.dispose();
    }
  }

  /// Handle scroll events and update visibility state
  void _handleScroll() {
    if (!hideOnScrollController.hasClients) return;

    final currentOffset = hideOnScrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    // At the very top, always show everything
    if (currentOffset <= 0) {
      if (!isHeaderVisible || !isBottomNavVisible) {
        setState(() {
          isHeaderVisible = true;
          isBottomNavVisible = true;
        });
      }
      _accumulatedDelta = 0;
      _lastScrollOffset = currentOffset;
      return;
    }

    // Accumulate scroll delta
    _accumulatedDelta += delta;

    // Check if we've scrolled enough to trigger a change
    if (_accumulatedDelta.abs() >= _scrollThreshold) {
      final scrollingDown = _accumulatedDelta > 0;

      if (scrollingDown && (isHeaderVisible || isBottomNavVisible)) {
        // Scrolling down - hide header and bottom nav
        setState(() {
          isHeaderVisible = false;
          isBottomNavVisible = false;
        });
      } else if (!scrollingDown && (!isHeaderVisible || !isBottomNavVisible)) {
        // Scrolling up - show header and bottom nav
        setState(() {
          isHeaderVisible = true;
          isBottomNavVisible = true;
        });
      }

      _accumulatedDelta = 0;
    }

    _lastScrollOffset = currentOffset;
  }

  /// Manually show both header and bottom nav
  void showAll() {
    if (!isHeaderVisible || !isBottomNavVisible) {
      setState(() {
        isHeaderVisible = true;
        isBottomNavVisible = true;
      });
    }
  }

  /// Manually hide both header and bottom nav
  void hideAll() {
    if (isHeaderVisible || isBottomNavVisible) {
      setState(() {
        isHeaderVisible = false;
        isBottomNavVisible = false;
      });
    }
  }

  /// Reset scroll tracking (useful after programmatic scrolls)
  void resetScrollTracking() {
    _accumulatedDelta = 0;
    if (hideOnScrollController.hasClients) {
      _lastScrollOffset = hideOnScrollController.offset;
    }
  }
}
