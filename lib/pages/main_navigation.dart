import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'package:rs_flutter/widgets/animated_visibility_wrapper.dart';
import 'package:rs_flutter/widgets/custom_loading_indicator.dart';
import 'home_page.dart';
import 'add_new_page.dart';
import 'info_page.dart';
import 'settings_page.dart';
import '../services/subscription_service.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  // Use timestamp to ensure unique key even across MainNavigation instances
  int _homePageRefreshKey = DateTime.now().millisecondsSinceEpoch;
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _hasRMCAccess = false;
  bool _isLoading = true;

  // Hide-on-scroll state for bottom navigation
  bool _isBottomNavVisible = true;
  double _lastScrollOffset = 0;
  double _accumulatedDelta = 0;
  static const double _scrollThreshold = 15.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final subscriptionInfo = await _subscriptionService.getSubscriptionInfo();
    if (mounted) {
      setState(() {
        _hasRMCAccess = subscriptionInfo.hasRMCAccess;
        _isLoading = false;
      });
    }
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;

      // Refresh HomePage when navigating to it
      if (index == 0) {
        _homePageRefreshKey++;
      }

      // Reset bottom nav visibility when changing tabs
      _isBottomNavVisible = true;
      _accumulatedDelta = 0;
    });
  }

  /// Handle scroll notifications from child pages
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final currentOffset = notification.metrics.pixels;

      // At the very top, always show bottom nav
      if (currentOffset <= 0) {
        if (!_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
        _accumulatedDelta = 0;
        _lastScrollOffset = currentOffset;
        return false;
      }

      // Accumulate scroll delta
      _accumulatedDelta += delta;

      // Check if we've scrolled enough to trigger a change
      if (_accumulatedDelta.abs() >= _scrollThreshold) {
        final scrollingDown = _accumulatedDelta > 0;

        if (scrollingDown && _isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = false;
          });
        } else if (!scrollingDown && !_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }

        _accumulatedDelta = 0;
      }

      _lastScrollOffset = currentOffset;
    }

    return false; // Allow notification to continue bubbling
  }

  List<Widget> _getPages() {
    if (_hasRMCAccess) {
      // RecallMatch users: show all pages including Add
      return [
        HomePage(
          key: ValueKey(_homePageRefreshKey),
          onNavigateToRecalls: () => _changeTab(2),
        ),
        const AddNewPage(),
        const InfoPage(),
        const SettingsPage(),
      ];
    } else {
      // Non-RecallMatch users: hide Add page
      return [
        HomePage(
          key: ValueKey(_homePageRefreshKey),
          onNavigateToRecalls: () => _changeTab(1), // Info tab moves to index 1
        ),
        const InfoPage(),
        const SettingsPage(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (_hasRMCAccess) {
      // RecallMatch users: show all nav items including Add
      return [
        BottomNavigationBarItem(
          icon: Semantics(
            label: 'Navigate to Home tab',
            button: true,
            child: const Icon(Icons.home),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Semantics(
            label: 'Navigate to Add tab',
            button: true,
            child: const Icon(Icons.add_circle),
          ),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Semantics(
            label: 'Navigate to Info tab',
            button: true,
            child: const Icon(Icons.info),
          ),
          label: 'Info',
        ),
        BottomNavigationBarItem(
          icon: Semantics(
            label: 'Navigate to Settings tab',
            button: true,
            child: const Icon(Icons.settings),
          ),
          label: 'Settings',
        ),
      ];
    } else {
      // Non-RecallMatch users: hide Add button
      return [
        BottomNavigationBarItem(
          icon: Semantics(
            label: 'Navigate to Home tab',
            button: true,
            child: const Icon(Icons.home),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Semantics(
            label: 'Navigate to Info tab',
            button: true,
            child: const Icon(Icons.info),
          ),
          label: 'Info',
        ),
        BottomNavigationBarItem(
          icon: Semantics(
            label: 'Navigate to Settings tab',
            button: true,
            child: const Icon(Icons.settings),
          ),
          label: 'Settings',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: CustomLoadingIndicator(
          size: LoadingIndicatorSize.medium,
        ),
      );
    }

    final pages = _getPages();

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Keyboard navigation: 1, 2, 3, 4 keys or Ctrl+1, Ctrl+2, Ctrl+3, Ctrl+4
          if (event.logicalKey == LogicalKeyboardKey.digit1 ||
              (HardwareKeyboard.instance.isControlPressed &&
                  event.logicalKey == LogicalKeyboardKey.digit1)) {
            _changeTab(0);
          } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
              (HardwareKeyboard.instance.isControlPressed &&
                  event.logicalKey == LogicalKeyboardKey.digit2)) {
            _changeTab(1);
          } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
              (HardwareKeyboard.instance.isControlPressed &&
                  event.logicalKey == LogicalKeyboardKey.digit3)) {
            _changeTab(2);
          } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
              (HardwareKeyboard.instance.isControlPressed &&
                  event.logicalKey == LogicalKeyboardKey.digit4)) {
            _changeTab(3);
          }
        }
      },
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: pages[_currentIndex],
        ),
        bottomNavigationBar: AnimatedVisibilityWrapper(
          isVisible: _isBottomNavVisible,
          direction: SlideDirection.down,
          child: Semantics(
            label: 'Bottom navigation bar',
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                _changeTab(index);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.secondary,
              selectedItemColor: AppColors.accentBlue,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              elevation: 8,
              selectedFontSize: 12,
              unselectedFontSize: 10,
              iconSize: 24,
              items: _getNavItems(),
            ),
          ),
        ),
      ),
    );
  }
}
