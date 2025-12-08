import 'package:flutter/material.dart';
import 'animated_visibility_wrapper.dart';

/// A convenience scaffold that provides hide-on-scroll functionality
/// for headers and bottom navigation.
///
/// This widget handles all the scroll tracking internally, making it
/// easy to add hide-on-scroll behavior to any page.
///
/// Example:
/// ```dart
/// HideOnScrollScaffold(
///   header: MyCustomHeader(),
///   body: ListView.builder(
///     itemCount: 100,
///     itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///   ),
///   bottomNavigation: MyBottomNav(),
/// )
/// ```
class HideOnScrollScaffold extends StatefulWidget {
  /// Optional header widget that will hide on scroll down
  final Widget? header;

  /// The main body content (should be scrollable)
  final Widget body;

  /// Optional bottom navigation that will hide on scroll down
  final Widget? bottomNavigation;

  /// Background color for the scaffold
  final Color? backgroundColor;

  /// Whether to enable hide-on-scroll behavior (default: true)
  final bool enableHideOnScroll;

  /// External scroll controller (optional - one will be created if not provided)
  final ScrollController? scrollController;

  /// Scroll threshold before hiding/showing (default: 15)
  final double scrollThreshold;

  /// Animation duration (default: 200ms)
  final Duration animationDuration;

  /// Whether to wrap with SafeArea (default: true)
  final bool useSafeArea;

  /// Floating action button
  final Widget? floatingActionButton;

  /// Floating action button location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const HideOnScrollScaffold({
    super.key,
    this.header,
    required this.body,
    this.bottomNavigation,
    this.backgroundColor,
    this.enableHideOnScroll = true,
    this.scrollController,
    this.scrollThreshold = 15.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.useSafeArea = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  State<HideOnScrollScaffold> createState() => _HideOnScrollScaffoldState();
}

class _HideOnScrollScaffoldState extends State<HideOnScrollScaffold> {
  late ScrollController _scrollController;
  bool _ownsController = false;
  bool _isHeaderVisible = true;
  bool _isBottomNavVisible = true;
  double _lastScrollOffset = 0;
  double _accumulatedDelta = 0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
      _ownsController = false;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }

    if (widget.enableHideOnScroll) {
      _scrollController.addListener(_handleScroll);
    }
  }

  @override
  void didUpdateWidget(HideOnScrollScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enableHideOnScroll != oldWidget.enableHideOnScroll) {
      if (widget.enableHideOnScroll) {
        _scrollController.addListener(_handleScroll);
      } else {
        _scrollController.removeListener(_handleScroll);
        // Show everything when disabled
        setState(() {
          _isHeaderVisible = true;
          _isBottomNavVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.enableHideOnScroll) {
      _scrollController.removeListener(_handleScroll);
    }
    if (_ownsController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    // At the very top, always show everything
    if (currentOffset <= 0) {
      if (!_isHeaderVisible || !_isBottomNavVisible) {
        setState(() {
          _isHeaderVisible = true;
          _isBottomNavVisible = true;
        });
      }
      _accumulatedDelta = 0;
      _lastScrollOffset = currentOffset;
      return;
    }

    // Accumulate scroll delta
    _accumulatedDelta += delta;

    // Check if we've scrolled enough to trigger a change
    if (_accumulatedDelta.abs() >= widget.scrollThreshold) {
      final scrollingDown = _accumulatedDelta > 0;

      if (scrollingDown && (_isHeaderVisible || _isBottomNavVisible)) {
        setState(() {
          _isHeaderVisible = false;
          _isBottomNavVisible = false;
        });
      } else if (!scrollingDown &&
          (!_isHeaderVisible || !_isBottomNavVisible)) {
        setState(() {
          _isHeaderVisible = true;
          _isBottomNavVisible = true;
        });
      }

      _accumulatedDelta = 0;
    }

    _lastScrollOffset = currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        // Header with animation
        if (widget.header != null)
          AnimatedVisibilityWrapper(
            isVisible: _isHeaderVisible || !widget.enableHideOnScroll,
            direction: SlideDirection.up,
            duration: widget.animationDuration,
            child: widget.header!,
          ),

        // Body - wrap with scroll controller if it's a known scrollable type
        Expanded(
          child: _wrapBodyWithController(widget.body),
        ),
      ],
    );

    if (widget.useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: content,
      bottomNavigationBar: widget.bottomNavigation != null
          ? AnimatedVisibilityWrapper(
              isVisible: _isBottomNavVisible || !widget.enableHideOnScroll,
              direction: SlideDirection.down,
              duration: widget.animationDuration,
              child: widget.bottomNavigation!,
            )
          : null,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  /// Attempt to inject our scroll controller into the body widget
  Widget _wrapBodyWithController(Widget body) {
    // For NotificationListener approach - more flexible
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // We're already handling scroll via the controller
        return false;
      },
      child: PrimaryScrollController(
        controller: _scrollController,
        child: body,
      ),
    );
  }
}
