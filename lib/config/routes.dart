import 'package:flutter/material.dart';

// Pages
import 'package:rs_flutter/pages/intro_page1.dart';
import 'package:rs_flutter/pages/home_page.dart';
import 'package:rs_flutter/pages/login_page.dart';
import 'package:rs_flutter/pages/sign_up_page.dart';
import 'package:rs_flutter/pages/main_navigation.dart';
import 'package:rs_flutter/pages/info_page.dart';
import 'package:rs_flutter/pages/settings_page.dart';
import 'package:rs_flutter/pages/subscribe_page.dart';
import 'package:rs_flutter/pages/all_recalls_page.dart';
import 'package:rs_flutter/pages/all_fda_recalls_page.dart';
import 'package:rs_flutter/pages/all_usda_recalls_page.dart';
import 'package:rs_flutter/pages/saved_recalls_page.dart';
import 'package:rs_flutter/pages/filtered_recalls_page.dart';
import 'package:rs_flutter/pages/advanced_filter_page.dart';
import 'package:rs_flutter/pages/saved_filters_page.dart';
import 'package:rs_flutter/pages/email_notifications_page.dart';
import 'package:rs_flutter/pages/push_notifications_page.dart';
import 'package:rs_flutter/pages/rmc_page.dart';
import 'package:rs_flutter/pages/all_vehicle_recalls_page.dart';
import 'package:rs_flutter/pages/all_tire_recalls_page.dart';
import 'package:rs_flutter/pages/all_child_seat_recalls_page.dart';
import 'package:rs_flutter/pages/nhtsa_recall_details_page.dart';
import 'package:rs_flutter/pages/recall_updates_page.dart';
import 'package:rs_flutter/pages/recall_notification_preferences_page.dart';
import 'package:rs_flutter/pages/vehicle_recall_alerts_page.dart';

/// Centralized route configuration for the app.
///
/// This class defines all named routes and provides a route generator
/// for dynamic routing with arguments.
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // ==================== Route Names ====================

  static const String intro = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String mainNavigation = '/main';
  static const String info = '/info';
  static const String settings = '/settings';
  static const String subscribe = '/subscribe';
  static const String allRecalls = '/recalls/all';
  static const String allFdaRecalls = '/recalls/fda';
  static const String allUsdaRecalls = '/recalls/usda';
  static const String savedRecalls = '/recalls/saved';
  static const String categoryFilter = '/filter/category';
  static const String advancedFilter = '/filter/advanced';
  static const String savedFilters = '/filter/saved';
  static const String emailNotifications = '/notifications/email';
  static const String pushNotifications = '/notifications/push';
  static const String recallUpdates = '/notifications/recall-updates';
  static const String notificationPreferences = '/notification-preferences';
  static const String rmc = '/rmc';
  static const String allVehicleRecalls = '/recalls/vehicles';
  static const String allTireRecalls = '/recalls/tires';
  static const String allChildSeatRecalls = '/recalls/child-seats';
  static const String vehicleRecallAlerts = '/vehicle-alerts';

  // Detail page routes (accept arguments)
  static const String fdaRecallDetails = '/recalls/fda/details';
  static const String usdaRecallDetails = '/recalls/usda/details';
  static const String nhtsaRecallDetails = '/recalls/nhtsa/details';
  static const String rmcDetails = '/rmc/details';
  static const String completedRmcDetails = '/rmc/completed/details';

  // ==================== Route Generator ====================

  /// Generates routes based on RouteSettings
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const IntroPage1());

      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());

      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpPage());

      case '/main':
        return MaterialPageRoute(builder: (_) => const MainNavigation());

      case '/info':
        return MaterialPageRoute(builder: (_) => const InfoPage());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      case '/subscribe':
        return MaterialPageRoute(builder: (_) => const SubscribePage());

      case '/recalls/all':
        return MaterialPageRoute(builder: (_) => const AllRecallsPage());

      case '/recalls/fda':
        return MaterialPageRoute(builder: (_) => const AllFDARecallsPage());

      case '/recalls/usda':
        return MaterialPageRoute(builder: (_) => const AllUSDARecallsPage());

      case '/recalls/saved':
        return MaterialPageRoute(builder: (_) => const SavedRecallsPage());

      case '/filter/category':
        return MaterialPageRoute(builder: (_) => const FilteredRecallsPage());

      case '/filter/advanced':
        return MaterialPageRoute(builder: (_) => const AdvancedFilterPage());

      case '/filter/saved':
        return MaterialPageRoute(builder: (_) => const SavedFiltersPage());

      case '/notifications/email':
        return MaterialPageRoute(
          builder: (_) => const EmailNotificationsPage(),
        );

      case '/notifications/push':
        return MaterialPageRoute(
          builder: (_) => const PushNotificationsPage(),
        );

      case '/notifications/recall-updates':
        return MaterialPageRoute(
          builder: (_) => const RecallUpdatesPage(),
        );

      case '/notification-preferences':
        return MaterialPageRoute(
          builder: (_) => const RecallNotificationPreferencesPage(),
        );

      case '/rmc':
        return MaterialPageRoute(builder: (_) => const RmcPage());

      case '/recalls/vehicles':
        return MaterialPageRoute(builder: (_) => const AllVehicleRecallsPage());

      case '/recalls/tires':
        return MaterialPageRoute(builder: (_) => const AllTireRecallsPage());

      case '/recalls/child-seats':
        return MaterialPageRoute(builder: (_) => const AllChildSeatRecallsPage());

      case '/vehicle-alerts':
        return MaterialPageRoute(builder: (_) => const VehicleRecallAlertsPage());

      case '/recalls/nhtsa/details':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || args['recall'] == null) return null;
        return MaterialPageRoute(
          builder: (_) => NhtsaRecallDetailsPage(recall: args['recall']),
        );

      // Detail pages with arguments would be handled here
      // Example:
      // case fdaRecallDetails:
      //   final args = settings.arguments as Map<String, dynamic>?;
      //   if (args == null) return null;
      //   return MaterialPageRoute(
      //     builder: (_) => FDARecallDetailsPage(recall: args['recall']),
      //   );

      default:
        return null;
    }
  }

  /// Returns a 404 page for unknown routes
  static Route<dynamic> unknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
    );
  }

  // ==================== Navigation Helpers ====================

  /// Navigate to a named route
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to a route and remove all previous routes
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Replace current route with a new route
  static Future<T?> navigateAndReplace<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, void>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Go back to previous screen
  static void goBack(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
}
