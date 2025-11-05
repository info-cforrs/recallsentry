import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'pages/intro_page1.dart';
import 'widgets/iphone_simulator.dart';
import 'pages/subscribe_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DEBUG: Uncomment the lines below to clear stored credentials on app start
  // This is useful for testing the guest user flow
  // print('🧹 DEBUG: Clearing stored auth tokens for guest user testing...');
  // await AuthService().logout();
  // SubscriptionService().clearCache();
  // print('✅ DEBUG: Auth tokens cleared - app will run as guest');

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RS Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const IPhoneSimulator(child: IntroPage1()),
      debugShowCheckedModeBanner: false,
      routes: {'/subscribe': (context) => const SubscribePage()},
    );
  }
}
