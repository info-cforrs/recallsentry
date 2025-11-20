import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/app_config.dart';
import '../widgets/notification_banner.dart';
import '../main.dart';
import '../pages/new_recalls_page.dart';
import '../pages/fda_recall_details_page.dart';
import '../pages/usda_recall_details_page.dart';
import 'recall_data_service.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('🔔 Background message: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _storage = const FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final String baseUrl = AppConfig.apiBaseUrl;

  String? _fcmToken;
  bool _isInitialized = false;

  /// Initialize FCM and register token
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('✅ FCM already initialized');
      }
      return;
    }

    // FCM is only supported on web, Android, and iOS - NOT on desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      if (kDebugMode) {
        debugPrint('⚠️ FCM not supported on desktop platforms (Windows/Linux/macOS)');
        debugPrint('✅ Skipping FCM initialization on ${Platform.operatingSystem}');
      }
      _isInitialized = true;
      return;
    }

    if (kDebugMode) {
      debugPrint('🌐 Initializing FCM for ${kIsWeb ? "Web" : "Mobile"} platform');
    }

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      if (kDebugMode) {
        debugPrint('📱 Requesting FCM permission...');
      }
      // Request permission for notifications
      final NotificationSettings settings = await _requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          debugPrint('✅ FCM permission granted');
          debugPrint('🔑 Getting FCM token...');
        }

        // Get FCM token
        _fcmToken = await _messaging.getToken();

        if (_fcmToken != null) {
          // SECURITY: Never log full tokens, even in debug mode
          if (kDebugMode) {
            debugPrint('🔑 FCM Token obtained successfully');
          }

          // Register token with backend
          if (kDebugMode) {
            debugPrint('📤 Registering FCM token with backend...');
          }
          await registerToken(_fcmToken!);

          // Listen for token refresh
          _messaging.onTokenRefresh.listen((newToken) {
            if (kDebugMode) {
              debugPrint('🔄 FCM Token refreshed');
            }
            _fcmToken = newToken;
            registerToken(newToken);
          });

          // Set up foreground message handler
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

          // Set up background message handler
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

          // Handle notification tap when app is in background
          FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

          // Check if app was opened from a notification
          final initialMessage = await _messaging.getInitialMessage();
          if (initialMessage != null) {
            _handleNotificationTap(initialMessage);
          }

          _isInitialized = true;
          if (kDebugMode) {
            debugPrint('✅ FCM initialized successfully');
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to get FCM token');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ FCM permission denied: ${settings.authorizationStatus}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing FCM: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    if (kDebugMode) {
      debugPrint('🔔 Initializing local notifications...');
    }

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          debugPrint('👆 Local notification tapped: ${response.payload}');
        }
        // Handle notification tap
      },
    );

    if (kDebugMode) {
      debugPrint('✅ Local notifications initialized');
    }
  }

  /// Request notification permission
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');
    }

    return settings;
  }

  /// Register FCM token with backend
  Future<void> registerToken(String token) async {
    try {
      // Get auth token
      final accessToken = await _storage.read(key: 'access_token');

      if (accessToken == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No access token - user not logged in. Will register token after login.');
        }
        return;
      }

      // Determine device type based on platform
      String deviceType = kIsWeb ? 'web' : 'mobile';
      String deviceName = kIsWeb ? 'Web Browser' : 'Mobile Device';

      if (kDebugMode) {
        debugPrint('📤 Registering FCM token...');
        debugPrint('   Device type: $deviceType');
        debugPrint('   Device name: $deviceName');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/fcm/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'token': token,
          'device_type': deviceType,
          'device_name': deviceName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          final data = json.decode(response.body);
          debugPrint('✅ FCM token registered with backend');
          debugPrint('   Created: ${data['created']}');
          debugPrint('   Token ID: ${data['token_id']}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to register FCM token: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error registering FCM token: $e');
      }
    }
  }

  /// Unregister FCM token from backend
  Future<void> unregisterToken() async {
    if (_fcmToken == null) return;

    try {
      final accessToken = await _storage.read(key: 'access_token');

      if (accessToken == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No access token - cannot unregister token');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('📤 Unregistering FCM token from backend...');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/fcm/unregister/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({'token': _fcmToken}),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ FCM token unregistered from backend');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to unregister FCM token: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error unregistering FCM token: $e');
      }
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('🔔 Foreground message received');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');
    }

    // Display the notification
    final notification = message.notification;
    if (notification != null) {
      final title = notification.title ?? 'RecallSentry';
      final body = notification.body ?? 'You have a new notification';

      if (kIsWeb) {
        // On web, show in-app banner notification (browser blocks foreground notifications)
        if (kDebugMode) {
          debugPrint('📱 Showing in-app notification banner');
        }

        // Extract image URL from notification data if available
        String? imageUrl = message.data['image_url'] as String?;

        // Convert relative URL to absolute URL if needed
        if (imageUrl != null && imageUrl.startsWith('/')) {
          imageUrl = '$baseUrl$imageUrl';
          if (kDebugMode) {
            debugPrint('   Image URL (converted): $imageUrl');
          }
        }

        NotificationBanner().show(
          title: title,
          body: body,
          imageUrl: imageUrl,
          onTap: () => _handleNotificationNavigation(message),
        );
      } else {
        // On mobile platforms, show a local notification
        await _showLocalNotification(
          title: title,
          body: body,
          payload: json.encode(message.data),
        );
      }
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kDebugMode) {
      debugPrint('📢 Showing local notification: $title');
    }

    const androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'Push Notifications',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('✅ Local notification displayed');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('👆 Notification tapped');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Data: ${message.data}');
    }

    _handleNotificationNavigation(message);
  }

  /// Handle notification navigation based on message data
  Future<void> _handleNotificationNavigation(RemoteMessage message) async {
    final fcmType = message.data['fcm_type'];
    if (kDebugMode) {
      debugPrint('🧭 Handling navigation for FCM type: $fcmType');
      debugPrint('   Data: ${message.data}');
    }

    if (fcmType != 'new_recalls') {
      if (kDebugMode) {
        debugPrint('⚠️ Navigation not implemented for FCM type: $fcmType');
      }
      return;
    }

    // Get count from message data (try recall_count first, then count)
    final countStr = (message.data['recall_count'] ?? message.data['count']) as String?;
    final count = int.tryParse(countStr ?? '0') ?? 0;

    if (kDebugMode) {
      debugPrint('📊 Recall count: $count');
    }

    if (count == 0) {
      if (kDebugMode) {
        debugPrint('⚠️ No recalls to navigate to');
      }
      return;
    }

    // Get navigator context
    final context = navigatorKey.currentContext;
    if (context == null) {
      if (kDebugMode) {
        debugPrint('⚠️ No navigator context available');
      }
      return;
    }

    if (count == 1) {
      // Single recall - navigate to recall details page
      final recallId = message.data['recall_id'] as String?;

      if (recallId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No recall_id in notification data - navigating to New Recalls page');
        }
        // Fall back to New Recalls page if no specific recall_id
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => const NewRecallsPage(),
          ),
        );
        return;
      }

      if (kDebugMode) {
        debugPrint('🔍 Fetching recall details for: $recallId');
      }

      try {
        // Fetch the recall data
        final recallService = RecallDataService();
        final recall = await recallService.getRecallById(recallId);

        if (recall == null) {
          if (kDebugMode) {
            debugPrint('⚠️ Could not find recall with id: $recallId');
          }
          return;
        }

        // Check if context is still valid after async operation
        if (!context.mounted) {
          if (kDebugMode) {
            debugPrint('⚠️ Context no longer mounted');
          }
          return;
        }

        // Navigate to appropriate details page based on agency
        if (kDebugMode) {
          debugPrint('✅ Navigating to ${recall.id.startsWith('FDA') ? 'FDA' : 'USDA'} recall details');
        }

        if (recall.id.startsWith('FDA')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => FdaRecallDetailsPage(recall: recall),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => UsdaRecallDetailsPage(recall: recall),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error fetching recall: $e');
        }
      }
    } else {
      // Multiple recalls - navigate to new recalls page
      if (kDebugMode) {
        debugPrint('✅ Navigating to New Recalls page');
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const NewRecallsPage(),
        ),
      );
    }
  }

  /// Get current FCM token
  String? get token => _fcmToken;

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;

  /// Manually refresh FCM token
  Future<void> refreshToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = await _messaging.getToken();

      if (_fcmToken != null) {
        if (kDebugMode) {
          debugPrint('🔄 FCM token manually refreshed');
        }
        await registerToken(_fcmToken!);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error refreshing FCM token: $e');
      }
    }
  }
}
