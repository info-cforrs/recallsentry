import 'package:flutter/material.dart';
import '../main.dart';

class NotificationBanner {
  static final NotificationBanner _instance = NotificationBanner._internal();
  factory NotificationBanner() => _instance;
  NotificationBanner._internal();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void show({
    required String title,
    required String body,
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    debugPrint('🎨 NotificationBanner.show() called');
    debugPrint('   Title: $title');
    debugPrint('   Body: $body');
    debugPrint('   Image URL: $imageUrl');
    debugPrint('   Has onTap callback: ${onTap != null}');

    // Get navigator context
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ No navigator context available for notification dialog');
      return;
    }

    // Show centered dialog instead of bottom SnackBar
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with notification icon
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Body text
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              // Image (if provided)
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    maxHeight: 120,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // If image fails to load, show placeholder
                        return Container(
                          height: 120,
                          width: 300,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white70,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // Dismiss button
            TextButton(
              onPressed: () {
                debugPrint('❌ Notification dismissed');
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Dismiss',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            // View button (if onTap callback provided)
            if (onTap != null)
              ElevatedButton(
                onPressed: () {
                  debugPrint('👆 View button clicked in notification dialog');
                  Navigator.of(dialogContext).pop(); // Close dialog first
                  onTap(); // Then execute navigation
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade700,
                ),
                child: const Text('View'),
              ),
          ],
        );
      },
    );
  }
}
