import 'package:flutter/material.dart';
import '../models/user_home.dart';
import '../pages/user_item_list_page.dart';

/// Home Portal Widget displaying home stats
/// Shows home name, total items, and recalled items count
class HomePortalWidget extends StatelessWidget {
  final UserHome? home;
  final int totalItems;
  final int recalledItems;
  final VoidCallback? onTap;

  const HomePortalWidget({
    super.key,
    this.home,
    required this.totalItems,
    required this.recalledItems,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // If no home data, show placeholder
    if (home == null) {
      return _buildPlaceholder(context);
    }

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          // Navigate to item list page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserItemListPage(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C5F7C), // Darker blue
              const Color(0xFF1E4A5F), // Even darker blue
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side: Home icon and name (1/3 width)
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Home icon
                  Image.asset(
                    'assets/images/Home_iconv2.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 30,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Home name
                  Text(
                    home!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Right side: Stats (2/3 width)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Total Items
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserItemListPage(),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Items: $totalItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Recalled Items
                  Row(
                    children: [
                      Text(
                        'Recalled Items: ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: recalledItems > 0
                              ? Colors.red
                              : Colors.green.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recalledItems.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress bar - Green (safe items) on top of Red (recalled items)
                  if (totalItems > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Item Status',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${totalItems - recalledItems} safe / $recalledItems recalled',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Stacked progress bar: Green (safe) on top of Red (recalled)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 8,
                            child: Stack(
                              children: [
                                // Red bar (recalled items) - full width background
                                Container(
                                  width: double.infinity,
                                  color: recalledItems > 0
                                      ? Colors.red.shade400
                                      : Colors.white.withValues(alpha: 0.2),
                                ),
                                // Green bar (safe items) - proportional width on top
                                FractionallySizedBox(
                                  widthFactor: (totalItems - recalledItems) / totalItems,
                                  child: Container(
                                    color: Colors.green.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder when no home is selected
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.home_outlined,
            color: Colors.white54,
            size: 40,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'No home selected',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
