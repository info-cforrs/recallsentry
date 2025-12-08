import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/subscription_service.dart';
import '../services/recallmatch_service.dart';
import '../models/recall_data.dart';
import '../models/user_home.dart';
import '../models/user_room.dart';
import 'fda_recall_details_page.dart';
import 'usda_recall_details_page.dart';
import 'cpsc_recall_details_page.dart';
import 'nhtsa_recall_details_page.dart';
import 'subscribe_page.dart';

/// Quick Check Results Page
///
/// Shows matching recalls based on item details entered.
/// Tier-based behavior:
/// - SmartFiltering: Shows matches only, no save option
/// - RecallMatch: Shows matches with option to save item to Home/Room
class QuickCheckResultsPage extends StatefulWidget {
  final SubscriptionTier tier;
  final String itemType;
  final Map<String, dynamic> itemDetails;
  final List<Map<String, dynamic>> matchingRecalls;

  const QuickCheckResultsPage({
    super.key,
    required this.tier,
    required this.itemType,
    required this.itemDetails,
    required this.matchingRecalls,
  });

  @override
  State<QuickCheckResultsPage> createState() => _QuickCheckResultsPageState();
}

class _QuickCheckResultsPageState extends State<QuickCheckResultsPage> {
  final RecallMatchService _recallMatchService = RecallMatchService();

  // For RecallMatch users - Home/Room selection
  List<UserHome> _userHomes = [];
  List<UserRoom> _userRooms = [];
  UserHome? _selectedHome;
  UserRoom? _selectedRoom;
  bool _isLoadingHomes = false;
  bool _isLoadingRooms = false;
  bool _isSaving = false;
  bool _showSaveSection = false;

  @override
  void initState() {
    super.initState();
    // Only load homes for RecallMatch users
    if (widget.tier == SubscriptionTier.recallMatch) {
      _loadUserHomes();
    }
  }

  Future<void> _loadUserHomes() async {
    setState(() {
      _isLoadingHomes = true;
    });

    try {
      final homes = await _recallMatchService.getUserHomes();
      if (mounted) {
        setState(() {
          _userHomes = homes;
          _isLoadingHomes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userHomes = [];
          _isLoadingHomes = false;
        });
      }
    }
  }

  Future<void> _loadRoomsForHome(int homeId) async {
    setState(() {
      _isLoadingRooms = true;
      _userRooms = [];
      _selectedRoom = null;
    });

    try {
      final rooms = await _recallMatchService.getRoomsByHome(homeId);
      if (mounted) {
        setState(() {
          _userRooms = rooms;
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userRooms = [];
          _isLoadingRooms = false;
        });
      }
    }
  }

  Future<void> _saveItemAndEnroll() async {
    if (_selectedHome == null || _selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a home and room'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Map fields based on item type
      String brandName = '';
      String productName = '';
      String modelNumber = '';
      String? upc;
      String? batchLotCode;
      String? vehicleYear;
      String? vehicleMake;
      String? vehicleModel;
      String? vehicleVin;
      String? tireDotCode;
      String? tireSize;
      String? childSeatModelNumber;
      String? manufacturer;

      switch (widget.itemType) {
        case 'household':
        case 'food':
          brandName = widget.itemDetails['brand_name'] ?? '';
          productName = widget.itemDetails['product_name'] ?? '';
          upc = widget.itemDetails['upc'];
          batchLotCode = widget.itemDetails['batch_lot_code'];
          break;
        case 'vehicle':
          vehicleMake = widget.itemDetails['make'];
          vehicleModel = widget.itemDetails['model'];
          vehicleYear = widget.itemDetails['year'];
          vehicleVin = widget.itemDetails['vin'];
          // Build brand/product name for display
          brandName = vehicleMake ?? '';
          productName = '${vehicleMake ?? ''} ${vehicleModel ?? ''}'.trim();
          break;
        case 'tires':
          manufacturer = widget.itemDetails['manufacturer'];
          modelNumber = widget.itemDetails['model'] ?? '';
          tireDotCode = widget.itemDetails['dot_code'];
          tireSize = widget.itemDetails['tire_size'];
          // Use manufacturer as brand
          brandName = manufacturer ?? '';
          productName = modelNumber;
          break;
        case 'child_seat':
          manufacturer = widget.itemDetails['manufacturer'];
          modelNumber = widget.itemDetails['model'] ?? '';
          childSeatModelNumber = widget.itemDetails['model_number'];
          upc = widget.itemDetails['upc'];
          // Use manufacturer as brand
          brandName = manufacturer ?? '';
          productName = modelNumber;
          break;
      }

      // Create the user item
      await _recallMatchService.createUserItem(
        homeId: _selectedHome!.id,
        roomId: _selectedRoom!.id,
        manufacturer: manufacturer ?? '',
        brandName: brandName,
        productName: productName,
        modelNumber: modelNumber,
        upc: upc,
        batchLotCode: batchLotCode,
        // Vehicle fields
        vehicleYear: vehicleYear,
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        vehicleVin: vehicleVin,
        // Tire fields
        tireDotCode: tireDotCode,
        tireSize: tireSize,
        // Child seat fields
        childSeatModelNumber: childSeatModelNumber,
        // Item category
        itemCategory: widget.itemType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item saved successfully! RecallMatch engine will monitor for recalls.'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _navigateToRecallDetails(RecallData recall) {
    Widget detailPage;

    switch (recall.agency.toUpperCase()) {
      case 'FDA':
        detailPage = FdaRecallDetailsPage(recall: recall);
        break;
      case 'USDA':
        detailPage = UsdaRecallDetailsPage(recall: recall);
        break;
      case 'CPSC':
        detailPage = CpscRecallDetailsPage(recall: recall);
        break;
      case 'NHTSA':
        detailPage = NhtsaRecallDetailsPage(recall: recall);
        break;
      default:
        // Default to FDA for unknown agencies
        detailPage = FdaRecallDetailsPage(recall: recall);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => detailPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMatches = widget.matchingRecalls.isNotEmpty;

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
          'Quick Check Results',
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
              // Result summary card
              _buildResultSummaryCard(hasMatches),

              const SizedBox(height: 24),

              // Matching recalls list
              if (hasMatches) ...[
                Text(
                  'POTENTIAL RECALL MATCHES (${widget.matchingRecalls.length})',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.matchingRecalls.map((match) => _buildRecallMatchCard(match)),
              ],

              // RecallMatch tier - Save option (show always, not just when matches found)
              if (widget.tier == SubscriptionTier.recallMatch) ...[
                const SizedBox(height: 24),
                _buildSaveItemSection(),
              ],

              // SmartFiltering tier - Upgrade prompt
              if (widget.tier == SubscriptionTier.smartFiltering) ...[
                const SizedBox(height: 24),
                _buildUpgradePrompt(),
              ],

              const SizedBox(height: 24),

              // Done button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummaryCard(bool hasMatches) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasMatches
              ? [const Color(0xFFFF9800), const Color(0xFFF57C00)]
              : [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            hasMatches ? Icons.warning_amber_rounded : Icons.check_circle,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            hasMatches
                ? 'Potential Recalls Found'
                : 'No Recalls Found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasMatches
                ? 'We found ${widget.matchingRecalls.length} potential recall${widget.matchingRecalls.length == 1 ? '' : 's'} matching your item. Review them below.'
                : 'Great news! We didn\'t find any active recalls matching your item details.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          if (!hasMatches) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Safe to Purchase',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecallMatchCard(Map<String, dynamic> match) {
    final recall = match['recall'] as RecallData;
    final score = match['score'] as double;
    final reasons = match['reasons'] as List<String>;

    Color scoreColor;
    String confidenceText;
    if (score >= 70) {
      scoreColor = Colors.red;
      confidenceText = 'High Match';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      confidenceText = 'Medium Match';
    } else {
      scoreColor = Colors.yellow.shade700;
      confidenceText = 'Low Match';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _navigateToRecallDetails(recall);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with score
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recall.productName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recall.brandName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scoreColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${score.toInt()}%',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            confidenceText,
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Match reasons
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: reasons.map((reason) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reason,
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Recall info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recall.agency,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Issued: ${_formatDate(recall.dateIssued)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveItemSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Save Item for Monitoring',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Toggle button
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSaveSection = !_showSaveSection;
                  });
                },
                icon: Icon(
                  _showSaveSection ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add this item to your household inventory for continuous recall monitoring.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          if (_showSaveSection) ...[
            const SizedBox(height: 20),

            // Home selection
            const Text(
              'SELECT HOME',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            if (_isLoadingHomes)
              const Center(child: CircularProgressIndicator())
            else if (_userHomes.isEmpty)
              const Text(
                'No homes available. Create a home in Home View first.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _userHomes.map((home) {
                  final isSelected = _selectedHome?.id == home.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedHome = home;
                        _selectedRoom = null;
                      });
                      _loadRoomsForHome(home.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentBlue : AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accentBlue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        home.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            if (_selectedHome != null) ...[
              const SizedBox(height: 16),

              // Room selection
              const Text(
                'SELECT ROOM',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              if (_isLoadingRooms)
                const Center(child: CircularProgressIndicator())
              else if (_userRooms.isEmpty)
                const Text(
                  'No rooms available. Create a room first.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _userRooms.map((room) {
                    final isSelected = _selectedRoom?.id == room.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRoom = room;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentBlue : AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.accentBlue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          room.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],

            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_selectedHome != null && _selectedRoom != null && !_isSaving)
                    ? _saveItemAndEnroll
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save & Monitor Item',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 40),
          const SizedBox(height: 12),
          const Text(
            'Want Continuous Monitoring?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade to RecallMatch to save items to your household inventory and get automatic alerts when new recalls match your products.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubscribePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade to RecallMatch',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
