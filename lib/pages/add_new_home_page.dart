import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'main_navigation.dart';
import '../services/recallmatch_service.dart';
import '../exceptions/api_exceptions.dart';
import '../models/user_home.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';

class AddNewHomePage extends StatefulWidget {
  const AddNewHomePage({super.key});

  @override
  State<AddNewHomePage> createState() => _AddNewHomePageState();
}

class _AddNewHomePageState extends State<AddNewHomePage> with HideOnScrollMixin {
  final TextEditingController _nameController = TextEditingController();
  final RecallMatchService _recallMatchService = RecallMatchService();
  bool _isLoading = false;
  bool _isLoadingHomes = false;
  List<UserHome> _existingHomes = [];

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    _loadExistingHomes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    disposeHideOnScroll();
    super.dispose();
  }

  Future<void> _loadExistingHomes() async {
    setState(() {
      _isLoadingHomes = true;
    });

    try {
      final homes = await _recallMatchService.getUserHomes();
      if (mounted) {
        setState(() {
          _existingHomes = homes;
          _isLoadingHomes = false;
        });
      }
    } catch (e) {
      // Silently fail - just show empty list
      if (mounted) {
        setState(() {
          _existingHomes = [];
          _isLoadingHomes = false;
        });
      }
    }
  }

  Future<void> _addNewHome() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a home name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save home to database
      await _recallMatchService.createHome(name);

      if (!mounted) return;

      // Reload the homes list to show the new home
      await _loadExistingHomes();

      if (!mounted) return;

      // Clear the input field
      _nameController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Home "$name" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'Add New Home',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Existing Homes Section
              if (_isLoadingHomes)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentBlue,
                      ),
                    ),
                  ),
                )
              else if (_existingHomes.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'YOUR HOMES',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${_existingHomes.length} total',
                            style: TextStyle(
                              color: AppColors.textPrimary.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            controller: hideOnScrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _existingHomes.length,
                            separatorBuilder: (context, index) => Divider(
                              color: AppColors.textPrimary.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final home = _existingHomes[index];
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentBlue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.home,
                                    color: AppColors.accentBlue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  home.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${home.roomCount} room${home.roomCount != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 48,
                          color: AppColors.textPrimary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No homes yet',
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              // NAME label
              const Text(
                'NAME *',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Name input field
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'My Home',
                  hintStyle: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.secondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Add New Home button
              Center(
                child: SizedBox(
                  width: 250,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addNewHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textPrimary,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add New Home',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
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
