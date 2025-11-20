import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../widgets/shared/shared_image_carousel.dart';
import '../widgets/shared/shared_recommendations_accordion.dart';
import '../widgets/shared/shared_product_distribution_accordion.dart';
import '../widgets/shared/shared_recommended_products_accordion.dart';
import '../widgets/usda_recall_details_card.dart';
import '../widgets/shared/shared_usda_resources_section.dart';
import '../services/recall_data_service.dart';
import '../services/api_service.dart';
import '../services/recall_sharing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_navigation.dart';
import 'rmc_details_page.dart';
import '../models/rmc_enrollment.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'package:rs_flutter/widgets/custom_loading_indicator.dart';
import '../services/subscription_service.dart';
import 'subscribe_page.dart';

class UsdaRecallDetailsPage extends StatefulWidget {
  final RecallData recall;
  const UsdaRecallDetailsPage({super.key, required this.recall});

  @override
  State<UsdaRecallDetailsPage> createState() => _UsdaRecallDetailsPageState();
}

class _UsdaRecallDetailsPageState extends State<UsdaRecallDetailsPage> {
  RecallData? _freshRecall;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLatestRecall();
  }

  Future<void> _fetchLatestRecall() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final recalls = await RecallDataService().getUsdaRecalls(
        forceRefresh: true,
      );
      final id = widget.recall.usdaRecallId;
      final fresh = recalls.firstWhere(
        (r) => r.usdaRecallId == id,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: FullPageLoadingIndicator(
          title: 'USDA Recall Details',
          message: 'Loading recall information...',
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            'USDA Recall Details',
            style: TextStyle(color: AppColors.textPrimary),
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
          child: const Text(
            'USDA Recall Details',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        color: AppColors.primary,
        child: SingleChildScrollView(
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
              // USDA Recall Details Card
              USDARecallDetailsCard(recall: recall),
              const SizedBox(height: 16),

              // Estimated Value (moved from card)
              if (recall.estItemValue.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 160,
                        child: Text(
                          'Estimated Value (each):',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          recall.estItemValue,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. Product Identification
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Identification:',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recall.productIdentification.trim().isNotEmpty
                          ? recall.productIdentification
                          : 'Not specified',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Reason for Recall (moved from below)
              if (recall.recallPhaReason.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason for Recall:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recall.recallPhaReason,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. Product Distribution (States) - Premium Feature
              _buildPremiumDetailSection(
                title: 'Product Distribution',
                premiumContent: SharedProductDistributionAccordion(
                  productDistribution: recall.productDistribution,
                  distributionMapUrl: recall.distributionMapUrl,
                ),
              ),

              // 4. Adverse Reactions
              if (recall.adverseReactions.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adverse Reactions:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recall.adverseReactions,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              // 5. Adverse Reaction Details
              if (recall.adverseReactionDetails.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adverse Reaction Details:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recall.adverseReactionDetails,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              // 6. Recommendations - Premium Feature
              _buildPremiumDetailSection(
                title: 'Recommendations',
                premiumContent: SharedRecommendationsAccordion(
                  recommendationsActions: recall.recommendationsActions,
                  remedy: recall.remedy,
                ),
              ),

              // 5. Resolution - Consumer Actions
              _buildResolutionSection(recall),

              // 6. Remedy
              if (recall.remedy.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remedy:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
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

              // 7. I have this Recalled Item
              _buildStartRecallProcessButton(context, recall),
              const SizedBox(height: 12),

              // 9. Recall Process
              _buildRecallProcessSection(context),

              // 10. Recommended Replacement Items - Premium Feature
              _buildPremiumDetailSection(
                title: 'Recommended Replacement Items',
                premiumContent: SharedRecommendedProductsAccordion(recall: recall),
              ),

              // USDA Resources Section (from original page)
              SharedUsdaResourcesSection(recall: recall),
              const SizedBox(height: 24),
              // --- Bottom Big Button Section ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: 'Open USDA Recall Alert Link',
                    button: true,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEC7A2D),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (recall.recallUrl.isNotEmpty) {
                          final url = Uri.parse(recall.recallUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        }
                      },
                      child: const Text(
                        'USDA Recall/Alert Link',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Semantics(
                    label: 'Subscribe for recall details',
                    button: true,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF00B6FF),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/subscribe');
                      },
                      child: const Text(
                        'SUBSCRIBE FOR DETAILS',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              // Recall ID (bottom left)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recall.usdaRecallId,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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

  void _showPremiumDetailsUpgradeModal() {
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
            'Premium recall details including Product Distribution, Recommendations, and Recommended Replacement Items are available with SmartFiltering (\$1.99/month) or RecallMatch (\$4.99/month).',
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubscribePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
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

  Widget _buildStartRecallProcessButton(
    BuildContext context,
    RecallData recall,
  ) {
    return FutureBuilder<SubscriptionInfo>(
      future: SubscriptionService().getSubscriptionInfo(),
      builder: (context, subscriptionSnapshot) {
        final hasRmcAccess = subscriptionSnapshot.data?.hasRMCAccess ?? false;

        return FutureBuilder<Map<String, dynamic>>(
          future: _getEnrollmentForCurrentUser(recall.databaseId!),
          builder: (context, snapshot) {
            final bool hasEnrollment =
                snapshot.hasData && snapshot.data!['enrollment'] != null;
            final String statusText;

            if (hasEnrollment) {
              // Show the current enrollment status
              final RmcEnrollment enrollment = snapshot.data!['enrollment'] as RmcEnrollment;
              final rmcStatus = enrollment.status;
              statusText = 'Status: $rmcStatus';
            } else {
              statusText = 'Start Recall Process';
            }

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: hasRmcAccess ? null : const Color(0xFFD1D1D1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: !hasRmcAccess
                      ? () {
                          // Show upgrade modal for non-RecallMatch users
                          _showRmcUpgradeModal();
                        }
                      : !hasEnrollment
                  ? () {
                      // Only show confirmation dialog if not started
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            title: const Text(
                              'Start Recall Process',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              'Are you ready to start managing this recall? This will activate the Recall Management Center for this item.',
                              style: TextStyle(color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
                                onPressed: () async {
                                  // Enroll recall in RMC with new enrollment system
                                  final navigator = Navigator.of(context);
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                                  try {
                                    // Create RMC enrollment with "Not Started" status
                                    final enrollment = await ApiService()
                                        .enrollRecallInRmc(
                                          recallId: recall.databaseId!,
                                          rmcStatus: 'Not Started',
                                        );

                                    if (!mounted) return;
                                    navigator.pop();

                                    // Navigate to RMC Details workflow page
                                    navigator.push(
                                      MaterialPageRoute(
                                        builder: (context) => RmcDetailsPage(
                                          recall: recall,
                                          enrollment: enrollment,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    navigator.pop();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to enroll recall in RMC: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Start Process',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  : () async {
                      // If already enrolled, use enrollment from snapshot and navigate to RMC workflow page
                      if (snapshot.hasData && snapshot.data!['enrollment'] != null) {
                        final enrollment = snapshot.data!['enrollment'] as RmcEnrollment;
                        if (!mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RmcDetailsPage(
                              recall: recall,
                              enrollment: enrollment,
                            ),
                          ),
                        );
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasRmcAccess ? const Color(0xFF00B6FF) : Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.list_alt,
                        color: hasRmcAccess ? AppColors.textPrimary : Colors.black54,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !hasEnrollment
                                ? 'I have this recalled item'
                                : 'Recall Management Center',
                            style: TextStyle(
                              color: hasRmcAccess ? AppColors.textPrimary : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasRmcAccess ? statusText : 'RecallMatch exclusive feature',
                            style: TextStyle(
                              color: hasRmcAccess ? AppColors.textSecondary : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      hasRmcAccess ? Icons.arrow_forward_ios : Icons.lock,
                      color: hasRmcAccess ? AppColors.textPrimary : Colors.black54,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildRecallProcessSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title and Learn More link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recall Process',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  // Open the Recall-Process.png image or navigate to a learn more page
                  // For now, you can add navigation logic here
                },
                child: const Text(
                  'Learn More',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 2: Four equally spaced columns with icons and text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProcessStep(
                'assets/images/Identify_Affected_Item.png',
                'Identify\nAffected Item',
              ),
              _buildProcessStep(
                'assets/images/Follow_Recall_Steps.png',
                'Follow Recall\nSteps',
              ),
              _buildProcessStep(
                'assets/images/Choose_Path.png',
                'Choose\nPath',
              ),
              _buildProcessStep(
                'assets/images/Receive_Resolution.png',
                'Resolution',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String iconPath, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 60, height: 60, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionSection(RecallData recall) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Resolution – Consumer Actions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          // Five equally spaced circular icons with labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRemedyCheckbox('Return', recall.remedyReturn),
              _buildRemedyCheckbox('Repair', recall.remedyRepair),
              _buildRemedyCheckbox('Replace', recall.remedyReplace),
              _buildRemedyCheckbox('Dispose', recall.remedyDispose),
              _buildRemedyCheckbox('N/A', recall.remedyNA),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemedyCheckbox(String label, String value) {
    bool isChecked = value.toUpperCase() == 'Y';
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            isChecked
                ? 'assets/images/Check_Circle_LightBG.png'
                : 'assets/images/Blank_Circle_LightBG.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
