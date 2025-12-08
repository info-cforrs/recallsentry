import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'add_new_household_item_photo_page.dart';
import 'add_new_food_item_photo_page.dart';
import 'add_new_vehicle_photo_page.dart';
import 'add_new_tires_photo_page.dart';
import 'add_new_child_seat_photo_page.dart';

/// Verify Recall Item Type Selection Page
///
/// Entry point for "I have this recalled item" flow.
/// Allows user to select what type of item they want to add and check for recalls.
/// Unlike Quick Check (which is pre-purchase), this flow adds the item to inventory
/// and checks if it matches any active recalls.
class VerifyRecallItemTypePage extends StatelessWidget {
  const VerifyRecallItemTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Recalled Item',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner - different from Quick Check
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800), // Orange for recall/safety theme
                      const Color(0xFFF57C00),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_home_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add Item to Inventory',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your item to your inventory so we can check it for safety recalls',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Info badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'We\'ll notify you if there\'s a recall',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Item type selection
              const Text(
                'SELECT ITEM TYPE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 16),

              // Item type cards
              _buildItemTypeCard(
                context: context,
                icon: 'assets/images/household_items_icon.png',
                fallbackIcon: Icons.home_outlined,
                title: 'Household Items',
                description: 'Electronics, appliances, furniture, and more',
                onTap: () => _navigateToItemCheck(context, 'household'),
              ),

              const SizedBox(height: 12),

              _buildItemTypeCard(
                context: context,
                icon: 'assets/images/food_icon.png',
                fallbackIcon: Icons.restaurant,
                title: 'Food & Beverages',
                description: 'Packaged foods, drinks, and supplements',
                onTap: () => _navigateToItemCheck(context, 'food'),
              ),

              const SizedBox(height: 12),

              _buildItemTypeCard(
                context: context,
                icon: 'assets/images/vehicle_icon.png',
                fallbackIcon: Icons.directions_car,
                title: 'Vehicles',
                description: 'Cars, trucks, motorcycles, and RVs',
                onTap: () => _navigateToItemCheck(context, 'vehicle'),
              ),

              const SizedBox(height: 12),

              _buildItemTypeCard(
                context: context,
                icon: 'assets/images/tires_icon.png',
                fallbackIcon: Icons.trip_origin,
                title: 'Tires',
                description: 'Car, truck, and motorcycle tires',
                onTap: () => _navigateToItemCheck(context, 'tires'),
              ),

              const SizedBox(height: 12),

              _buildItemTypeCard(
                context: context,
                icon: 'assets/images/child_seat_icon.png',
                fallbackIcon: Icons.child_care,
                title: 'Child Seats',
                description: 'Car seats, boosters, and accessories',
                onTap: () => _navigateToItemCheck(context, 'child_seat'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemTypeCard({
    required BuildContext context,
    required String icon,
    required IconData fallbackIcon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.secondary,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    icon,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          fallbackIcon,
                          color: AppColors.accentBlue,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToItemCheck(BuildContext context, String itemType) {
    Widget page;

    switch (itemType) {
      case 'household':
        page = const AddNewHouseholdItemPhotoPage(
          isVerifyRecallMode: true,
        );
        break;
      case 'food':
        page = const AddNewFoodItemPhotoPage(
          isVerifyRecallMode: true,
        );
        break;
      case 'vehicle':
        page = const AddNewVehiclePhotoPage(
          isVerifyRecallMode: true,
        );
        break;
      case 'tires':
        page = const AddNewTiresPhotoPage(
          isVerifyRecallMode: true,
        );
        break;
      case 'child_seat':
        page = const AddNewChildSeatPhotoPage(
          isVerifyRecallMode: true,
        );
        break;
      default:
        page = const AddNewHouseholdItemPhotoPage(
          isVerifyRecallMode: true,
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
