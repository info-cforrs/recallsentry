import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/saved_recalls_service.dart';
import 'services/error_reporting_service.dart';
import 'pages/intro_page1.dart';
import 'widgets/iphone_simulator.dart';
import 'widgets/notification_banner.dart';
import 'pages/subscribe_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for persistent caching
  debugPrint('💾 Initializing Hive for local storage...');
  await Hive.initFlutter();
  debugPrint('✅ Hive initialized successfully');

  // Initialize sqflite for desktop platforms (Windows, macOS, Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    debugPrint('💾 Initializing sqflite_ffi for desktop platform...');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('✅ Database factory initialized successfully');
  }

  // Initialize Firebase
  try {
    debugPrint('🔥 Starting Firebase initialization...');

    // Check if Firebase is already initialized (prevents duplicate initialization)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint('ℹ️ Firebase already initialized, skipping...');
    }
    debugPrint('🌐 Platform: ${kIsWeb ? "Web" : "Desktop"}');

    // Initialize Error Reporting (Crashlytics)
    debugPrint('📊 Starting Error Reporting initialization...');
    await ErrorReportingService.initialize();
    debugPrint('✅ Error Reporting Service initialized');

    // Initialize FCM (Firebase Cloud Messaging)
    debugPrint('🔔 Starting FCM initialization...');
    await FCMService().initialize();
    debugPrint('✅ FCM Service initialization completed');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // DEBUG: Uncomment the lines below to clear stored credentials on app start
  // This is useful for testing the guest user flow
  // print('🧹 DEBUG: Clearing stored auth tokens for guest user testing...');
  // await AuthService().logout();
  // SubscriptionService().clearCache();
  // print('✅ DEBUG: Auth tokens cleared - app will run as guest');

  // Cleanup old saved recalls (older than 6 months)
  try {
    debugPrint('🧹 Cleaning up old saved recalls...');
    final removedCount = await SavedRecallsService().cleanupOldSavedRecalls();
    if (removedCount > 0) {
      debugPrint('✅ Removed $removedCount old saved recall(s)');
    } else {
      debugPrint('✅ No old recalls to clean up');
    }
  } catch (e) {
    debugPrint('⚠️ Error cleaning up old recalls: $e');
  }

  // Initialize window manager ONLY on desktop platforms (Windows, macOS, Linux)
  // Skip on mobile (iOS, Android) and web
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    // iPhone 15 dimensions with some padding for the frame and shadows
    const double windowWidth =
        450.0; // iPhone width (393) + padding for frame/shadows
    const double windowHeight =
        920.0; // iPhone height (852) + padding for frame/shadows

    WindowOptions windowOptions = const WindowOptions(
      size: Size(windowWidth, windowHeight),
      minimumSize: Size(windowWidth, windowHeight),
      maximumSize: Size(windowWidth, windowHeight),
      center: true,
      backgroundColor: Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Wrap app with ProviderScope to enable Riverpod state management
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Global navigator key for navigation from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecallSentry',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: NotificationBanner().scaffoldMessengerKey,
      theme: AppTheme.darkTheme,
      home: const IPhoneSimulator(child: IntroPage1()),
      debugShowCheckedModeBanner: false,
      routes: {'/subscribe': (context) => const SubscribePage()},
    );
  }
}
