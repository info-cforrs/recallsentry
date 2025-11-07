import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../models/rmc_enrollment.dart';
import '../services/api_service.dart';
import 'rmc_status_page.dart';
import 'main_navigation.dart';
import '../widgets/custom_back_button.dart';

class RmcPage extends StatefulWidget {
  const RmcPage({super.key});

  @override
  State<RmcPage> createState() => _RmcPageState();
}

class _RmcPageState extends State<RmcPage> with WidgetsBindingObserver {
  List<RmcEnrollment> _enrollments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedTimePeriod = 'ALL';
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEnrollments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload data when app comes back to foreground
    if (state == AppLifecycleState.resumed && _hasLoadedOnce) {
      _loadEnrollments();
    }
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch active enrollments (excludes "Not Active" status)
      final enrollments = await ApiService().fetchActiveRmcEnrollments();

      setState(() {
        _enrollments = enrollments;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load RMC enrollments: $e';
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  // New status counters based on RMC enrollment statuses
  int _getNotStartedCount() {
    return _enrollments
        .where((e) => e.status == 'Not Started')
        .length;
  }

  int _getDiscontinuedUseCount() {
    return _enrollments
        .where((e) => e.status == 'In Progress - Discontinued Use')
        .length;
  }

  int _getContactedManufacturerCount() {
    return _enrollments
        .where((e) => e.status == 'In Progress - Contacted Manufacturer')
        .length;
  }

  int _getInProgressCount() {
    return _enrollments
        .where((e) {
          final status = e.status.trim().toLowerCase();
          // Only count true "In Progress" statuses, excluding specific subcategories
          return status != 'closed' &&
                 status != 'completed' &&
                 status != 'not started' &&
                 status != 'in progress - discontinued use' &&
                 status != 'in progress - contacted manufacturer';
        })
        .length;
  }

  int _getCompletedCount() {
    return _enrollments
        .where((e) {
          final status = e.status.trim().toLowerCase();
          return status == 'completed' || status == 'closed';
        })
        .length;
  }

  List<RmcEnrollment> _getInProgressEnrollments() {
    return _enrollments
        .where((e) {
          final status = e.status.trim().toLowerCase();
          return status != 'closed' && status != 'completed' && status != 'not started';
        })
        .toList();
  }

  double _calculateTotalRecallValue() {
    // Get date range based on selected time period
    final now = DateTime.now();
    DateTime? startDate;

    switch (_selectedTimePeriod) {
      case 'TODAY':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'LAST WEEK':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'LAST MONTH':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'LAST 3 MONTHS':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'LAST YEAR':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case 'ALL':
        startDate = null; // No filter
        break;
    }

    // Sum estimated_value for completed enrollments within the time period
    double total = 0.0;
    for (var enrollment in _enrollments) {
      if (enrollment.status == 'Completed') {
        // Check if enrollment is within the selected time period
        if (startDate == null ||
            (enrollment.completedAt != null && enrollment.completedAt!.isAfter(startDate))) {
          // Use the user's estimated value from the enrollment
          if (enrollment.estimatedValue != null) {
            total += enrollment.estimatedValue!;
          }
        }
      }
    }

    return total;
  }

  List<RmcEnrollment> _getEnrollmentsByStatus(String status) {
    return _enrollments
        .where((e) => e.status == status)
        .toList();
  }

  List<RmcEnrollment> _getCompletedEnrollments() {
    return _enrollments
        .where((e) {
          final status = e.status.trim().toLowerCase();
          return status == 'completed' || status == 'closed';
        })
        .toList();
  }

  void _navigateToStatusList(String title, String? statusFilter, List<RmcEnrollment> enrollments) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RmcStatusPage(
          pageTitle: title,
          statusFilter: statusFilter,
          filteredEnrollments: enrollments,
        ),
      ),
    );
    // Reload data after returning from list page
    _loadEnrollments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with App Icon and Page Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CustomBackButton(),
                  const SizedBox(width: 8),
                  // App Icon - Clickable to return to Home
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) =>
                              const MainNavigation(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/images/shield_logo3.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Page Title
                  const Expanded(
                    child: Text(
                      'Recall Management Center',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Atlanta',
                        color: Colors.white,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            // Body Content
            Expanded(
              child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEnrollments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEnrollments,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Recall Status Section
                        const Text(
                          'Recall Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Status Buttons - New statuses from RMC Details Test Page
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildStatusButton(
                                'NOT STARTED',
                                _getNotStartedCount(),
                                () => _navigateToStatusList(
                                  'Not Started',
                                  'Not Started',
                                  _getEnrollmentsByStatus('Not Started'),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildStatusButton(
                                'DISCONTINUED USE',
                                _getDiscontinuedUseCount(),
                                () => _navigateToStatusList(
                                  'Discontinued Use',
                                  'In Progress - Discontinued Use',
                                  _getEnrollmentsByStatus('In Progress - Discontinued Use'),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildStatusButton(
                                'CONTACTED MANUFACTURER',
                                _getContactedManufacturerCount(),
                                () => _navigateToStatusList(
                                  'Contacted Manufacturer',
                                  'In Progress - Contacted Manufacturer',
                                  _getEnrollmentsByStatus('In Progress - Contacted Manufacturer'),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildStatusButton(
                                'IN PROGRESS',
                                _getInProgressCount(),
                                () => _navigateToStatusList(
                                  'In Progress',
                                  null, // No specific status filter - show all in progress
                                  _getInProgressEnrollments(),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildStatusButton(
                                'COMPLETED',
                                _getCompletedCount(),
                                () => _navigateToStatusList(
                                  'Completed',
                                  null, // Show both Completed and Closed
                                  _getCompletedEnrollments(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Recall Value Section
                        const Text(
                          'Recall Value',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Time Period Selector
                        Row(
                          children: [
                            const Text(
                              'Time Period:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedTimePeriod,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'TODAY',
                                        child: Text('TODAY'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'LAST WEEK',
                                        child: Text('LAST WEEK'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'LAST MONTH',
                                        child: Text('LAST MONTH'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'LAST 3 MONTHS',
                                        child: Text('LAST 3 MONTHS'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'LAST YEAR',
                                        child: Text('LAST YEAR'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'ALL',
                                        child: Text('ALL'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedTimePeriod = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Est. Recalled Items Value
                        const Text(
                          'Est. Recalled Items Value:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${_calculateTotalRecallValue().toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 32,
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C3E50),
        selectedItemColor: const Color(0xFF64B5F6),
        unselectedItemColor: Colors.white54,
        currentIndex: 2,
        elevation: 8,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 0),
                ),
                (route) => false,
              );
              break;
            case 1:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 1),
                ),
                (route) => false,
              );
              break;
            case 2:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 2),
                ),
                (route) => false,
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF5DADE2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
