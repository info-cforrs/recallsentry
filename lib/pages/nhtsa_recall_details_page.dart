import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../widgets/shared/shared_image_carousel.dart';
import '../widgets/shared/shared_recommendations_accordion.dart';
import '../widgets/shared/shared_product_distribution_accordion.dart';
import '../widgets/shared/shared_recommended_products_accordion.dart';
import '../widgets/nhtsa_vehicle_recall_details_card.dart';
import '../widgets/nhtsa_tire_recall_details_card.dart';
import '../widgets/nhtsa_child_seat_recall_details_card.dart';
import '../services/recall_data_service.dart';
import '../services/api_service.dart';
import '../services/recall_sharing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_navigation.dart';
import 'rmc_details_page.dart';
import 'add_item_from_recall_page.dart';
import '../models/rmc_enrollment.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'package:rs_flutter/widgets/custom_loading_indicator.dart';
import '../services/subscription_service.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';
import 'subscribe_page.dart';

class NhtsaRecallDetailsPage extends StatefulWidget {
  final RecallData recall;
  const NhtsaRecallDetailsPage({super.key, required this.recall});

  @override
  State<NhtsaRecallDetailsPage> createState() => _NhtsaRecallDetailsPageState();
}

class _NhtsaRecallDetailsPageState extends State<NhtsaRecallDetailsPage> with HideOnScrollMixin {
  RecallData? _freshRecall;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    _fetchLatestRecall();
  }

  @override
  void dispose() {
    disposeHideOnScroll();
    super.dispose();
  }

  Future<void> _fetchLatestRecall() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Fetch based on recall type
      List<RecallData> recalls;
      final recallType = widget.recall.nhtsaRecallType.toLowerCase();

      if (recallType == 'vehicle') {
        recalls = await RecallDataService().getNhtsaVehicleRecalls(forceRefresh: true);
      } else if (recallType == 'tire') {
        recalls = await RecallDataService().getNhtsaTireRecalls(forceRefresh: true);
      } else if (recallType == 'child seat') {
        recalls = await RecallDataService().getNhtsaChildSeatRecalls(forceRefresh: true);
      } else {
        // Default to vehicle recalls
        recalls = await RecallDataService().getNhtsaVehicleRecalls(forceRefresh: true);
      }

      // Match by ID or database ID
      final id = widget.recall.id;
      final dbId = widget.recall.databaseId;
      final nhtsaId = widget.recall.nhtsaRecallId;
      final fresh = recalls.firstWhere(
        (r) => r.id == id || r.databaseId == dbId || r.nhtsaRecallId == nhtsaId,
        orElse: () => widget.recall,
      );
      setState(() {
        _freshRecall = fresh;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load latest recall data: $e';
        _isLoading = false;
        _freshRecall = widget.recall;
      });
    }
  }

  /// Get the appropriate details card based on NHTSA recall type
  Widget _buildDetailsCard(RecallData recall) {
    final recallType = recall.nhtsaRecallType.toLowerCase();

    switch (recallType) {
      case 'vehicle':
        return NHTSAVehicleRecallDetailsCard(recall: recall);
      case 'tire':
        return NHTSATireRecallDetailsCard(recall: recall);
      case 'child seat':
        return NHTSAChildSeatRecallDetailsCard(recall: recall);
      default:
        // Default to vehicle card
        return NHTSAVehicleRecallDetailsCard(recall: recall);
    }
  }

  /// Get the page title based on NHTSA recall type
  String _getPageTitle() {
    final recallType = widget.recall.nhtsaRecallType.toLowerCase();

    switch (recallType) {
      case 'vehicle':
        return 'Vehicle Recall Details';
      case 'tire':
        return 'Tire Recall Details';
      case 'child seat':
        return 'Child Seat Recall Details';
      default:
        return 'NHTSA Recall Details';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: FullPageLoadingIndicator(
          title: _getPageTitle(),
          message: 'Loading recall information...',
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            _getPageTitle(),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          elevation: 0,
        ),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: AppColors.error)),
        ),
      );
    }

    final recall = _freshRecall ?? widget.recall;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Go back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Semantics(
          header: true,
          child: Text(
            _getPageTitle(),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        color: AppColors.primary,
        child: SingleChildScrollView(
          controller: hideOnScrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Carousel
              SharedImageCarousel(
                imageUrls: recall.getAllImageUrls(),
                showIndicators: false,
                height: 220,
                width: double.infinity,
                borderRadius: 18,
                onShareTap: () {
                  RecallSharingService().showShareDialog(context, recall);
                },
              ),
              const SizedBox(height: 18),

              // NHTSA Recall Details Card (type-specific)
              _buildDetailsCard(recall),
              const SizedBox(height: 24),

              // Corrective Action / Remedy
              if (recall.remedy.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Corrective Action:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recall.remedy,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              // Notification Dates Section
              if (_hasNotificationDates(recall))
                _buildNotificationDatesSection(recall),

              // 3. Product Distribution (States) - Premium Feature
              _buildPremiumDetailSection(
                title: 'Product Distribution',
                premiumContent: SharedProductDistributionAccordion(
                  productDistribution: recall.productDistribution,
                  distributionMapUrl: recall.distributionMapUrl,
                ),
              ),

              // Recommendations section
              if (recall.recommendationsActions.trim().isNotEmpty)
                SharedRecommendationsAccordion(
                  recommendationsActions: recall.recommendationsActions,
                  remedy: recall.remedy,
                ),

              // Recommended Products section
              if (recall.recommendations.isNotEmpty)
                SharedRecommendedProductsAccordion(recall: recall),

              // RMC Enrollment Section
              if (recall.databaseId != null)
                _buildRmcEnrollmentSection(recall),

              // Official NHTSA Link
              if (recall.recallUrl.trim().isNotEmpty)
                _buildOfficialLinkSection(recall),

              // Recall ID (bottom left)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recall.nhtsaRecallId.isNotEmpty
                        ? 'Campaign: ${recall.nhtsaRecallId}'
                        : recall.id,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
          backgroundColor: AppColors.secondary,
          selectedItemColor: AppColors.accentBlue,
          unselectedItemColor: AppColors.textTertiary,
          currentIndex: 1, // Recalls tab selected
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
      ),
    );
  }

  bool _hasNotificationDates(RecallData recall) {
    return recall.nhtsaPlannedDealerNotificationDate != null ||
           recall.nhtsaPlannedOwnerNotificationDate != null ||
           recall.nhtsaOwnerNotificationLetterMailedDate != null;
  }

  Widget _buildNotificationDatesSection(RecallData recall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Dates:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (recall.nhtsaPlannedDealerNotificationDate != null)
            _buildDateRow('Dealer Notification:', recall.nhtsaPlannedDealerNotificationDate!),
          if (recall.nhtsaPlannedOwnerNotificationDate != null)
            _buildDateRow('Owner Notification:', recall.nhtsaPlannedOwnerNotificationDate!),
          if (recall.nhtsaOwnerNotificationLetterMailedDate != null)
            _buildDateRow('Letter Mailed:', recall.nhtsaOwnerNotificationLetterMailedDate!),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            _formatDate(date),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildOfficialLinkSection(RecallData recall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official NHTSA Information:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final url = Uri.parse(recall.recallUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View on NHTSA.gov',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Official recall information',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRmcEnrollmentSection(RecallData recall) {
    return FutureBuilder<SubscriptionInfo>(
      future: SubscriptionService().getSubscriptionInfo(),
      builder: (context, subscriptionSnapshot) {
        final hasRmcAccess = subscriptionSnapshot.data?.hasRMCAccess ?? false;

        return FutureBuilder<Map<String, dynamic>>(
          future: _getEnrollmentForCurrentUser(recall.databaseId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final enrollment = snapshot.data?['enrollment'] as RmcEnrollment?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recall Resolution:',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      if (!hasRmcAccess) {
                        // Show upgrade modal for non-RecallMatch users
                        _showRmcUpgradeModal();
                      } else if (enrollment != null) {
                        // Already enrolled - navigate to RMC Details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RmcDetailsPage(
                              recall: recall,
                              enrollment: enrollment,
                            ),
                          ),
                        );
                      } else {
                        // Not enrolled - navigate to Add Item from Recall flow
                        // Simple flow to add item and auto-enroll in RMC
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddItemFromRecallPage(
                              recall: recall,
                            ),
                          ),
                        );
                        // Refresh to show updated enrollment status
                        if (mounted) {
                          setState(() {});
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: hasRmcAccess ? AppColors.secondary : const Color(0xFFD1D1D1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: !hasRmcAccess
                                  ? Colors.grey[400]
                                  : enrollment != null
                                      ? AppColors.success.withValues(alpha: 0.2)
                                      : AppColors.accentBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              !hasRmcAccess
                                  ? Icons.lock
                                  : enrollment != null
                                      ? Icons.check_circle
                                      : Icons.play_circle_outline,
                              color: !hasRmcAccess
                                  ? Colors.black54
                                  : enrollment != null
                                      ? AppColors.success
                                      : AppColors.accentBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  !hasRmcAccess
                                      ? 'I have this recalled item'
                                      : enrollment != null
                                          ? 'Resolution In Progress'
                                          : 'I have this recalled item',
                                  style: TextStyle(
                                    color: hasRmcAccess ? AppColors.textPrimary : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  !hasRmcAccess
                                      ? 'RecallMatch exclusive feature'
                                      : enrollment != null
                                          ? 'Status: ${enrollment.status}'
                                          : 'Start Recall Process',
                                  style: TextStyle(
                                    color: hasRmcAccess ? AppColors.textSecondary : Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            hasRmcAccess ? Icons.arrow_forward_ios : Icons.lock,
                            color: hasRmcAccess ? AppColors.textSecondary : Colors.black54,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getEnrollmentForCurrentUser(int recallId) async {
    try {
      // Fetch ONLY the current user's enrollments (not all users)
      final enrollments = await ApiService().fetchRmcEnrollments();

      // Filter to find the enrollment for this specific recall
      final userEnrollment = enrollments.where((e) => e.recallId == recallId).firstOrNull;

      return {'enrollment': userEnrollment};
    } catch (e) {
      return {'enrollment': null};
    }
  }

  // Helper widget to wrap premium detail sections
  Widget _buildPremiumDetailSection({
    required String title,
    required Widget premiumContent,
  }) {
    return FutureBuilder<SubscriptionInfo>(
      future: SubscriptionService().getSubscriptionInfo(),
      builder: (context, snapshot) {
        final hasPremiumAccess = snapshot.data?.isPremium ?? false;

        if (hasPremiumAccess) {
          // Show the actual premium content
          return premiumContent;
        } else {
          // Show locked/greyed-out version
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD1D1D1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _showPremiumDetailsUpgradeModal(),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.black54,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Upgrade to SmartFiltering or RecallMatch for details',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black54,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  void _showRmcUpgradeModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 8),
              Text(
                'Upgrade Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Recall Management Center (RMC) is an exclusive RecallMatch feature. Upgrade to RecallMatch (\$4.99/month) to access step-by-step recall resolution workflows, household inventory tracking, SmartScan, and automated RecallMatch engine.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubscribePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF2A4A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPremiumDetailsUpgradeModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.premium, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Premium Feature',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Upgrade to SmartFiltering or RecallMatch to access detailed product distribution information and other premium features.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubscribePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
