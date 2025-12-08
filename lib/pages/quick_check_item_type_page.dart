import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/subscription_service.dart';
import 'add_new_household_item_photo_page.dart';
import 'add_new_food_item_photo_page.dart';
import 'add_new_vehicle_photo_page.dart';
import 'add_new_tires_photo_page.dart';
import 'add_new_child_seat_photo_page.dart';

/// Quick Check Item Type Selection Page
///
/// Allows user to select what type of item they want to check.
/// Based on item type, navigates to appropriate Quick Check details page.
class QuickCheckItemTypePage extends StatelessWidget {
  final SubscriptionTier tier;

  const QuickCheckItemTypePage({
    super.key,
    required this.tier,
  });

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
          'Quick Check',
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
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50),
                      const Color(0xFF388E3C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Check Before You Buy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the type of item you want to check for recalls',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tier == SubscriptionTier.recallMatch
                                ? Icons.workspace_premium
                                : Icons.star,
                            color: tier == SubscriptionTier.recallMatch
                                ? const Color(0xFFFFD700)
                                : Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tier == SubscriptionTier.recallMatch
                                ? 'RecallMatch - Full Access'
                                : 'SmartFiltering - Check Only',
                            style: const TextStyle(
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
        page = AddNewHouseholdItemPhotoPage(
          isQuickCheckMode: true,
          quickCheckTier: tier,
        );
        break;
      case 'food':
        page = AddNewFoodItemPhotoPage(
          isQuickCheckMode: true,
          quickCheckTier: tier,
        );
        break;
      case 'vehicle':
        page = AddNewVehiclePhotoPage(
          isQuickCheckMode: true,
          quickCheckTier: tier,
        );
        break;
      case 'tires':
        page = AddNewTiresPhotoPage(
          isQuickCheckMode: true,
          quickCheckTier: tier,
        );
        break;
      case 'child_seat':
        page = AddNewChildSeatPhotoPage(
          isQuickCheckMode: true,
          quickCheckTier: tier,
        );
        break;
      default:
        page = AddNewHouseholdItemPhotoPage(
          isQuickCheckMode: true,
          quickCheckTier: tier,
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
