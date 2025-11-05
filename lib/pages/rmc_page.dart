import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../services/api_service.dart';
import 'rmc_list_page.dart';
import 'main_navigation.dart';

class RmcPage extends StatefulWidget {
  const RmcPage({super.key});

  @override
  State<RmcPage> createState() => _RmcPageState();
}

class _RmcPageState extends State<RmcPage> {
  List<RecallData> _activeRecalls = [];
  bool _isLoading = true;
  String? _error;
  String _selectedTimePeriod = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadActiveRecalls();
  }

  Future<void> _loadActiveRecalls() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activeRecalls = await ApiService().fetchActiveRecalls();

      setState(() {
        _activeRecalls = activeRecalls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load active recalls: $e';
        _isLoading = false;
      });
    }
  }

  int _getOpenCount() {
    // Count recalls that are NOT completed
    return _activeRecalls
        .where((r) => r.recallResolutionStatus != 'Completed')
        .length;
  }

  int _getWaitingRefundCount() {
    // Count recalls with status: Return 1B, Return 1A, or Dispose 1A
    return _activeRecalls.where((r) {
      final status = r.recallResolutionStatus;
      return status == 'Return 1B: Item Shipped Back' ||
          status == 'Return 1A: Brought to local Retailer' ||
          status == 'Dispose 1A: Brought to local Retailer';
    }).length;
  }

  int _getWaitingRefundByLocalRetailerCount() {
    // Count recalls with status: Dispose 1A
    return _activeRecalls
        .where((r) =>
            r.recallResolutionStatus == 'Dispose 1A: Brought to local Retailer')
        .length;
  }

  int _getWaitingRefundByServiceCenterCount() {
    // Count recalls with status: Repair 1A
    return _activeRecalls
        .where((r) =>
            r.recallResolutionStatus == 'Repair 1A: Brought to Service Center')
        .length;
  }

  int _getWaitingToRepairItemCount() {
    // Count recalls with status: Repair 2A
    return _activeRecalls
        .where((r) =>
            r.recallResolutionStatus == 'Repair 2A: Received Repair Kit or Parts')
        .length;
  }

  int _getClosedCount() {
    // Count recalls with status: Completed
    return _activeRecalls
        .where((r) => r.recallResolutionStatus == 'Completed')
        .length;
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

    // Sum est_item_value for completed recalls within the time period
    double total = 0.0;
    for (var recall in _activeRecalls) {
      if (recall.recallResolutionStatus == 'Completed') {
        // Check if recall is within the selected time period
        if (startDate == null || recall.dateIssued.isAfter(startDate)) {
          // Parse est_item_value (remove $ and commas, convert to double)
          final valueStr = recall.estItemValue
              .replaceAll('\$', '')
              .replaceAll(',', '')
              .trim();
          if (valueStr.isNotEmpty) {
            try {
              total += double.parse(valueStr);
            } catch (e) {
              // Skip if can't parse est_item_value
            }
          }
        }
      }
    }

    return total;
  }

  List<RecallData> _getRecallsByStatus(List<String> statuses) {
    return _activeRecalls
        .where((r) => statuses.contains(r.recallResolutionStatus))
        .toList();
  }

  void _navigateToStatusList(String title, List<RecallData> recalls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RmcListPage(
          pageTitle: title,
          filteredRecalls: recalls,
        ),
      ),
    );
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
                        'assets/images/app_icon.png',
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
                  const Text(
                    'Recall Management Center',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Atlanta',
                      color: Colors.white,
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
                        onPressed: _loadActiveRecalls,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadActiveRecalls,
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

                        // Status Buttons
                        _buildStatusButton(
                          'OPEN',
                          _getOpenCount(),
                          () => _navigateToStatusList(
                            'Open Recalls',
                            _activeRecalls
                                .where((r) => r.recallResolutionStatus != 'Completed')
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildStatusButton(
                          'WAITING REFUND',
                          _getWaitingRefundCount(),
                          () => _navigateToStatusList(
                            'Waiting Refund',
                            _getRecallsByStatus([
                              'Return 1B: Item Shipped Back',
                              'Return 1A: Brought to local Retailer',
                              'Dispose 1A: Brought to local Retailer',
                            ]),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildStatusButton(
                          'WAITING REFUND BY\nLOCAL RETAILER',
                          _getWaitingRefundByLocalRetailerCount(),
                          () => _navigateToStatusList(
                            'Waiting Refund by Local Retailer',
                            _getRecallsByStatus([
                              'Dispose 1A: Brought to local Retailer',
                            ]),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildStatusButton(
                          'WAITING REFUND BY\nSERVICE CENTER',
                          _getWaitingRefundByServiceCenterCount(),
                          () => _navigateToStatusList(
                            'Waiting Refund by Service Center',
                            _getRecallsByStatus([
                              'Repair 1A: Brought to Service Center',
                            ]),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildStatusButton(
                          'WAITING TO REPAIR ITEM\nWITH PROVIDED PARTS',
                          _getWaitingToRepairItemCount(),
                          () => _navigateToStatusList(
                            'Waiting to Repair Item',
                            _getRecallsByStatus([
                              'Repair 2A: Received Repair Kit or Parts',
                            ]),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildStatusButton(
                          'CLOSED',
                          _getClosedCount(),
                          () => _navigateToStatusList(
                            'Completed Recalls',
                            _getRecallsByStatus(['Completed']),
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
