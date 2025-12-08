import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'main_navigation.dart';
import 'add_new_household_item_photo_page.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';

class AddNewItemPage extends StatefulWidget {
  const AddNewItemPage({super.key});

  @override
  State<AddNewItemPage> createState() => _AddNewItemPageState();
}

class _AddNewItemPageState extends State<AddNewItemPage> with HideOnScrollMixin {
  @override
  void initState() {
    super.initState();
    initHideOnScroll();
  }

  @override
  void dispose() {
    disposeHideOnScroll();
    super.dispose();
  }

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
          'Add New Item',
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
          controller: hideOnScrollController,
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
                // Household Items
                ListTile(
                  leading: const Icon(Icons.shopping_basket, color: Colors.white70),
                  title: const Text(
                    'Household Items',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddNewHouseholdItemPhotoPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Colors.white24),
                // Vehicles
                ListTile(
                  leading: const Icon(Icons.directions_car, color: Colors.white70),
                  title: const Text(
                    'Vehicles',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onTap: () {
                    // TODO: Navigate to Add Vehicle page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vehicles - Coming soon'),
                        backgroundColor: AppColors.accentBlue,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Colors.white24),
                // Tires
                ListTile(
                  leading: const Icon(Icons.album, color: Colors.white70),
                  title: const Text(
                    'Tires',
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onTap: () {
                    // TODO: Navigate to Add Tire page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tires - Coming soon'),
                        backgroundColor: AppColors.accentBlue,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
          currentIndex: 1, // Add tab
          onTap: (index) {
            if (index == 0) {
              // Home tab
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 0),
                ),
                (route) => false,
              );
            } else if (index == 1) {
              // Add tab - go back to Add New page
              Navigator.of(context).pop();
            } else if (index == 2) {
              // Info tab
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 2),
                ),
                (route) => false,
              );
            } else if (index == 3) {
              // Settings tab
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 3),
                ),
                (route) => false,
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.secondary,
          selectedItemColor: AppColors.accentBlue,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          elevation: 8,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          iconSize: 24,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: 'Info',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
