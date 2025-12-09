/// Widget Test Helpers
///
/// Common utilities for widget testing including:
/// - MaterialApp wrapper for pumping widgets
/// - Mock navigation observer
/// - Common finders and matchers
///
/// To use: import 'package:rs_flutter/test/helpers/widget_test_helpers.dart';
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget in MaterialApp for testing
/// This provides the necessary context (MediaQuery, Theme, Navigator, etc.)
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: child,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
  );
}

/// Wraps a widget in MaterialApp with a Scaffold
Widget createTestableWidgetWithScaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
  );
}

/// Creates a MaterialApp with custom routes for navigation testing
Widget createTestableWidgetWithRoutes(
  Widget home, {
  Map<String, WidgetBuilder>? routes,
  NavigatorObserver? navigatorObserver,
}) {
  return MaterialApp(
    home: home,
    routes: routes ?? {},
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
  );
}

/// Mock NavigatorObserver for tracking navigation events
class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];
  final List<Route<dynamic>> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) replacedRoutes.add(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void reset() {
    pushedRoutes.clear();
    poppedRoutes.clear();
    replacedRoutes.clear();
  }
}

/// Common widget finders
class TestFinders {
  /// Find a TextFormField by its label or hint text
  static Finder textFieldByLabel(String label) {
    return find.widgetWithText(TextFormField, label);
  }

  /// Find a TextField by key
  static Finder textFieldByKey(Key key) {
    return find.byKey(key);
  }

  /// Find an ElevatedButton by its text
  static Finder elevatedButtonByText(String text) {
    return find.widgetWithText(ElevatedButton, text);
  }

  /// Find any button by its text
  static Finder buttonByText(String text) {
    return find.text(text);
  }

  /// Find a SnackBar
  static Finder snackBar() {
    return find.byType(SnackBar);
  }

  /// Find a SnackBar with specific text
  static Finder snackBarWithText(String text) {
    return find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(text),
    );
  }

  /// Find a CircularProgressIndicator (loading indicator)
  static Finder loadingIndicator() {
    return find.byType(CircularProgressIndicator);
  }

  /// Find an error text (typically red)
  static Finder errorText(String text) {
    return find.text(text);
  }

  /// Find an IconButton by icon
  static Finder iconButton(IconData icon) {
    return find.widgetWithIcon(IconButton, icon);
  }

  /// Find a Checkbox
  static Finder checkbox() {
    return find.byType(Checkbox);
  }

  /// Find a Switch
  static Finder switchWidget() {
    return find.byType(Switch);
  }
}

/// Common widget actions
class TestActions {
  /// Enter text into a TextField
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Tap a widget and pump
  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  /// Tap and wait for animations
  static Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Scroll until a widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable,
  ) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: scrollable,
    );
  }

  /// Wait for a duration (e.g., for debounce)
  static Future<void> wait(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
  }

  /// Pump and settle with timeout
  static Future<void> settleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, timeout);
  }
}

/// Matchers for widget testing
class TestMatchers {
  /// Check if a widget is enabled
  static Matcher get isEnabled => _IsEnabled();

  /// Check if a widget is disabled
  static Matcher get isDisabled => _IsDisabled();
}

class _IsEnabled extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is Finder) {
      final widget = item.evaluate().single.widget;
      if (widget is ElevatedButton) return widget.onPressed != null;
      if (widget is TextButton) return widget.onPressed != null;
      if (widget is IconButton) return widget.onPressed != null;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('widget is enabled');
}

class _IsDisabled extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is Finder) {
      final widget = item.evaluate().single.widget;
      if (widget is ElevatedButton) return widget.onPressed == null;
      if (widget is TextButton) return widget.onPressed == null;
      if (widget is IconButton) return widget.onPressed == null;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('widget is disabled');
}

/// Extension methods for WidgetTester
extension WidgetTesterExtensions on WidgetTester {
  /// Enter text and dismiss keyboard
  Future<void> enterTextAndDismiss(Finder finder, String text) async {
    await enterText(finder, text);
    await testTextInput.receiveAction(TextInputAction.done);
    await pump();
  }

  /// Find and tap a widget by text
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pump();
  }

  /// Find and tap a widget by icon
  Future<void> tapByIcon(IconData icon) async {
    await tap(find.byIcon(icon));
    await pump();
  }

  /// Verify a SnackBar is shown with text
  void expectSnackBar(String text) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.text(text)),
      findsOneWidget,
    );
  }

  /// Verify no SnackBar is shown
  void expectNoSnackBar() {
    expect(find.byType(SnackBar), findsNothing);
  }
}
