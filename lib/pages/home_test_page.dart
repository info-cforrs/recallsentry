import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'home_page.dart';

class HomeTestPage extends StatefulWidget {
  const HomeTestPage({super.key});

  @override
  State<HomeTestPage> createState() => _HomeTestPageState();
}

class _HomeTestPageState extends State<HomeTestPage> {
  final ScrollController _scrollController = ScrollController();

  final Map<String, int> _categoryCounts = {
    'food': 15,
    'cosmetics': 8,
    'drugs': 12,
    'home': 6,
    'clothing': 4,
    'childSeats': 3,
    'powerTools': 7,
    'electronics': 11,
    'vehicles': 9,
    'tires': 5,
    'toys': 10,
    'pets': 14,
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCategoryCard({
    required String? imagePath,
    required IconData icon,
    required String label,
    required int? badgeCount,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped: $label')),
        );
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5DADE2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                size: 36,
                                color: const Color(0xFF2C3E50),
                              );
                            },
                          )
                        : Icon(
                            icon,
                            size: 36,
                            color: const Color(0xFF2C3E50),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Test - Carousel Only'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text(
              'Go to Real Home',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF34495E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Title for Category Carousel
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recalls by Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category Carousel
              SizedBox(
                height: 140,
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final offset = pointerSignal.scrollDelta.dy;
                      _scrollController.jumpTo(
                        _scrollController.offset + offset,
                      );
                    }
                  },
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                      _buildCategoryCard(
                        imagePath: 'assets/images/food_beverage_category_button.png',
                        icon: Icons.restaurant,
                        label: 'Food &\nBeverages',
                        badgeCount: _categoryCounts['food'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/cosmetics_category_button.png',
                        icon: Icons.brush,
                        label: 'Cosmetics &\nPersonal Care',
                        badgeCount: _categoryCounts['cosmetics'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/otc_category_button.png',
                        icon: Icons.medication,
                        label: 'OTC Drugs &\nSupplements',
                        badgeCount: _categoryCounts['drugs'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/home_furniture_category_button.png',
                        icon: Icons.chair,
                        label: 'Home &\nFurniture',
                        badgeCount: _categoryCounts['home'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/clothing_category_button.png',
                        icon: Icons.checkroom,
                        label: 'Clothing',
                        badgeCount: _categoryCounts['clothing'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/child_seats_category_button.png',
                        icon: Icons.child_care,
                        label: 'Child Seats &\nAccessories',
                        badgeCount: _categoryCounts['childSeats'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/power_tools_category_button.png',
                        icon: Icons.build,
                        label: 'Power Tools &\nLawn Care',
                        badgeCount: _categoryCounts['powerTools'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/electronics_category_button.png',
                        icon: Icons.devices,
                        label: 'Electronics &\nAppliances',
                        badgeCount: _categoryCounts['electronics'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/vehicles_category_button.png',
                        icon: Icons.directions_car,
                        label: 'Vehicles',
                        badgeCount: _categoryCounts['vehicles'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/tires_category_button.png',
                        icon: Icons.trip_origin,
                        label: 'Tires',
                        badgeCount: _categoryCounts['tires'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/toys_category_button.png',
                        icon: Icons.toys,
                        label: 'Toys',
                        badgeCount: _categoryCounts['toys'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/pets_veterinary_category_button.png',
                        icon: Icons.pets,
                        label: 'Pets &\nVeterinary',
                        badgeCount: _categoryCounts['pets'],
                      ),
                    ],
                  ),
                ),
              ),
            ),

              const SizedBox(height: 24),

              // Instructions
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Instructions:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('1. Use MOUSE SCROLL WHEEL on the carousel above'),
                        Text('2. Or click and drag left/right on the carousel'),
                        Text('3. Tap any category card to see a message'),
                        Text('4. Use "Go to Real Home" button to navigate back'),
                        SizedBox(height: 12),
                        Text(
                          'NOTE: On Windows desktop, horizontal scrolling requires using the scroll wheel while hovering over the carousel, or clicking and dragging.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
