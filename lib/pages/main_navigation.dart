import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'home_page.dart';
import 'info_page.dart';
import 'settings_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  int _homePageRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;

      // Refresh HomePage when navigating to it
      if (index == 0) {
        _homePageRefreshKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        key: ValueKey(_homePageRefreshKey),
        onNavigateToRecalls: () => _changeTab(1),
      ),
      const InfoPage(),
      const SettingsPage(),
    ];

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Keyboard navigation: 1, 2, 3 keys or Ctrl+1, Ctrl+2, Ctrl+3
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
          }
        }
      },
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: Semantics(
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
            items: [
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
            ],
          ),
        ),
      ),
    );
  }
}
