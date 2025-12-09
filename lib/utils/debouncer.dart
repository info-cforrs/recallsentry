import 'dart:async';

/// A utility class for debouncing function calls.
///
/// Debouncing ensures that a function is only called after a specified
/// delay has passed since the last call. This is useful for search fields
/// and other inputs where you want to wait for the user to stop typing.
///
/// Example usage:
/// ```dart
/// final _searchDebouncer = Debouncer(milliseconds: 300);
///
/// void onSearchChanged(String query) {
///   _searchDebouncer.run(() {
///     // This will only execute 300ms after the last call
///     _performSearch(query);
///   });
/// }
///
/// @override
/// void dispose() {
///   _searchDebouncer.dispose();
///   super.dispose();
/// }
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Run the action after the debounce delay.
  /// If called again before the delay expires, the timer resets.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancel any pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose of the debouncer and cancel any pending action.
  void dispose() {
    cancel();
  }

  /// Check if there's a pending action.
  bool get isActive => _timer?.isActive ?? false;
}

/// A typedef for void callbacks (for clarity)
typedef VoidCallback = void Function();
