import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'add_new_home_page.dart';
import 'add_new_room_page.dart';
import 'add_new_item_page.dart';
import '../services/subscription_service.dart';
import '../widgets/recallmatch_paywall.dart';

class AddNewPage extends StatefulWidget {
  const AddNewPage({super.key});

  @override
  State<AddNewPage> createState() => _AddNewPageState();
}

class _AddNewPageState extends State<AddNewPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  /// Check if user has RecallMatch subscription, show paywall if not
  Future<void> _checkRecallMatchAccess(Widget destination) async {
    final subscriptionInfo = await _subscriptionService.getSubscriptionInfo();

    if (!mounted) return;

    if (subscriptionInfo.hasRMCAccess) {
      // User has RecallMatch subscription - allow access
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => destination,
        ),
      );
    } else {
      // User doesn't have RecallMatch - show paywall
      await RecallMatchPaywall.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Add New',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            color: const Color(0xFF2A4A5C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white70),
                  title: Row(
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RecallMatch',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onTap: () => _checkRecallMatchAccess(const AddNewHomePage()),
                ),
                const Divider(height: 1, color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.meeting_room, color: Colors.white70),
                  title: Row(
                    children: [
                      const Text(
                        'Room',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RecallMatch',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onTap: () => _checkRecallMatchAccess(const AddNewRoomPage()),
                ),
                const Divider(height: 1, color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.white70),
                  title: Row(
                    children: [
                      const Text(
                        'Item',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RecallMatch',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onTap: () => _checkRecallMatchAccess(const AddNewItemPage()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
