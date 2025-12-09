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
import 'services/deep_link_service.dart';
import 'services/consent_service.dart';
import 'services/gamification_service.dart';
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

    // Apply user consent preferences to services
    debugPrint('🔒 Loading and applying consent preferences...');
    try {
      final consentPrefs = await ConsentService().getPreferences();
      // Apply crash reporting consent
      await ErrorReportingService.setCrashlyticsCollectionEnabled(
        consentPrefs.crashReportingEnabled,
      );
      // Apply gamification consent
      GamificationService().setEnabled(consentPrefs.gamificationEnabled);
      debugPrint('✅ Consent preferences applied: '
          'crash=${consentPrefs.crashReportingEnabled}, '
          'gamification=${consentPrefs.gamificationEnabled}');
    } catch (e) {
      debugPrint('⚠️ Error applying consent preferences: $e');
    }

    // NOTE: FCM initialization moved to post-frame callback for faster startup
    // See _initServices() in _MyAppState
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

  // Cleanup old saved recalls (deferred to background - non-blocking)
  // This runs after a delay to not block startup
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      debugPrint('🧹 Cleaning up old saved recalls (background)...');
      final removedCount = await SavedRecallsService().cleanupOldSavedRecalls();
      if (removedCount > 0) {
        debugPrint('✅ Removed $removedCount old saved recall(s)');
      } else {
        debugPrint('✅ No old recalls to clean up');
      }
    } catch (e) {
      debugPrint('⚠️ Error cleaning up old recalls: $e');
    }
  });

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize services after the first frame for faster startup
    // This defers heavy operations until the UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  Future<void> _initServices() async {
    // Initialize FCM (deferred from main() for faster startup - saves 1-3 seconds)
    // Only on mobile platforms where FCM is used
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      debugPrint('🔔 Starting FCM initialization (deferred)...');
      await FCMService().initialize();
      debugPrint('✅ FCM Service initialization completed');

      // Initialize deep links after FCM
      debugPrint('🔗 Initializing Deep Link Service...');
      await DeepLinkService().initialize(navigatorKey);
      debugPrint('✅ Deep Link Service initialized');
    }
  }

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
