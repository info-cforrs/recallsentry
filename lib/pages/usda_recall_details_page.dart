import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../widgets/shared/shared_image_carousel.dart';
import '../widgets/shared/shared_adverse_reactions_accordion.dart';
import '../widgets/shared/shared_recommendations_accordion.dart';
import '../widgets/shared/shared_remedy_section.dart';
import '../widgets/shared/shared_product_distribution_accordion.dart';
import '../widgets/shared/shared_recommended_products_accordion.dart';
import '../widgets/USDA_Recall_Details_Card.dart';
import '../widgets/shared/shared_usda_resources_section.dart';
import '../services/recall_data_service.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_navigation.dart';
import 'rmc_details_page.dart';

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
      print('🔄 Fetching fresh USDA recalls with forceRefresh=true...');
      final recalls = await RecallDataService().getUsdaRecalls(
        forceRefresh: true,
      );
      final id = widget.recall.usdaRecallId;
      print('🔍 Looking for recall with USDA ID: $id');
      final fresh = recalls.firstWhere(
        (r) => r.usdaRecallId == id,
        orElse: () => widget.recall,
      );
      print('📦 Found recall with ${fresh.recommendations.length} recommendations');
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
      return Scaffold(
        backgroundColor: const Color(0xFF1D3547),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D3547),
          title: const Text(
            'USDA Recall Details V3',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1D3547),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D3547),
          title: const Text(
            'USDA Recall Details V3',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final recall = _freshRecall ?? widget.recall;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3547),
        title: const Text(
          'USDA Recall Details V3',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFF1D3547),
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
              ),
              const SizedBox(height: 18),
              // USDA Recall Details Card
              USDARecallDetailsCard(recall: recall),
              const SizedBox(height: 16),
              // Start Recall Process button (always visible)
              _buildStartRecallProcessButton(context, recall),
              const SizedBox(height: 12),
              if (recall.recallPhaReason.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason for Recall:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recall.recallPhaReason,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              SharedProductDistributionAccordion(
                productDistribution: recall.productDistribution,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Identification:',
                      style: TextStyle(
                        color: Colors.white,
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
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              // Accordions
              SharedAdverseReactionsAccordion(
                adverseReactions: recall.adverseReactions,
                adverseReactionDetails: recall.adverseReactionDetails,
              ),
              SharedRecommendationsAccordion(
                recommendationsActions: recall.recommendationsActions,
                remedy: recall.remedy,
              ),
              SharedRemedySection(recall: recall),
              // Recommended Replacement Items Section
              SharedRecommendedProductsAccordion(recall: recall),
              // USDA Resources Section (from original page)
              SharedUsdaResourcesSection(recall: recall),
              const SizedBox(height: 24),
              // --- Bottom Big Button Section ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
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
                  const SizedBox(height: 40),
                  TextButton(
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C3E50),
        selectedItemColor: const Color(0xFF64B5F6),
        unselectedItemColor: Colors.white54,
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

  Widget _buildStartRecallProcessButton(BuildContext context, RecallData recall) {
    return FutureBuilder<List>(
      future: ApiService().fetchRmcEnrollmentsByRecallFilter(recall.databaseId!),
      builder: (context, snapshot) {
        final bool hasEnrollment = snapshot.hasData && snapshot.data!.isNotEmpty;
        final String statusText = hasEnrollment
            ? 'Tap to manage recall'
            : 'Start Recall Process';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: !hasEnrollment ? () {
            // Only show confirmation dialog if not started
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF2A4A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: const Text(
                    'Start Recall Process',
                    style: TextStyle(
                      color: Colors.white,
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
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                      onPressed: () async {
                        // Enroll recall in RMC with new enrollment system
                        try {
                          // Create RMC enrollment with "Not Started" status
                          final enrollment = await ApiService().enrollRecallInRmc(
                            recallId: recall.databaseId!,
                            status: 'Not Started',
                          );

                          if (!mounted) return;
                          Navigator.of(context).pop();

                          // Navigate to RMC Details workflow page
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RmcDetailsPage(
                                recall: recall,
                                enrollment: enrollment,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to enroll recall in RMC: $e'),
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
          } : () async {
            // If already enrolled, fetch enrollment and navigate to RMC workflow page
            try {
              final enrollments = await ApiService().fetchRmcEnrollmentsByRecallFilter(recall.databaseId!);
              if (enrollments.isNotEmpty) {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RmcDetailsPage(
                      recall: recall,
                      enrollment: enrollments.first,
                    ),
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load enrollment: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.list_alt,
                    color: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
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
  }
}
