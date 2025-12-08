import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

/// Service to handle deep links from email notifications
/// Supports URLs like:
///   - recallsentry://recalls
///   - recallsentry://settings
///   - recallsentry://settings/notifications
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the deep link service with a navigator key
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    // Handle app opened from a deep link (cold start)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('[DeepLink] Initial link: $initialLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('[DeepLink] Error getting initial link: $e');
    }

    // Handle deep links while app is running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('[DeepLink] Received link: $uri');
        _handleDeepLink(uri);
      },
      onError: (error) {
        debugPrint('[DeepLink] Stream error: $error');
      },
    );
  }

  /// Handle the deep link and navigate to appropriate screen
  void _handleDeepLink(Uri uri) {
    if (_navigatorKey?.currentState == null) {
      debugPrint('[DeepLink] Navigator not ready yet');
      return;
    }

    final path = uri.path.isEmpty ? uri.host : uri.path;
    debugPrint('[DeepLink] Handling path: $path');

    switch (path) {
      case 'recalls':
      case '/recalls':
        // Navigate to recalls list
        _navigateToRecalls();
        break;
      case 'settings':
      case '/settings':
        // Navigate to settings
        _navigateToSettings();
        break;
      case 'settings/notifications':
      case '/settings/notifications':
        // Navigate to notification settings
        _navigateToNotificationSettings();
        break;
      default:
        debugPrint('[DeepLink] Unknown path: $path');
    }
  }

  void _navigateToRecalls() {
    debugPrint('[DeepLink] Navigating to recalls...');
    // Navigate to the home/recalls screen
    // The app starts on IntroPage1 which leads to the main app
    // For now, we'll just ensure the app is on the main screen
    _navigatorKey?.currentState?.popUntil((route) => route.isFirst);
  }

  void _navigateToSettings() {
    debugPrint('[DeepLink] Navigating to settings...');
    // Navigate to settings page
    // You may need to implement a specific navigation based on your app structure
    _navigatorKey?.currentState?.popUntil((route) => route.isFirst);
    // TODO: Push to settings page when available
  }

  void _navigateToNotificationSettings() {
    debugPrint('[DeepLink] Navigating to notification settings...');
    // Navigate to notification settings
    _navigatorKey?.currentState?.popUntil((route) => route.isFirst);
    // TODO: Push to notification settings page when available
  }

  /// Dispose of the stream subscription
  void dispose() {
    _linkSubscription?.cancel();
  }
}
