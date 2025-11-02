import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../widgets/shared/shared_image_carousel.dart';
import '../widgets/shared/shared_adverse_reactions_accordion.dart';
import '../widgets/shared/shared_recommendations_accordion.dart';
import '../widgets/shared/shared_product_distribution_accordion.dart';
import '../widgets/shared/shared_recommended_products_accordion.dart';
import '../widgets/FDA_Recall_Details_Card.dart';
import '../widgets/shared/shared_fda_manufacturer_retailer_accordion.dart';
import '../widgets/shared/shared_fda_resources_section.dart';
import '../services/recall_data_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_navigation.dart';

class FdaRecallDetailsPageV2 extends StatefulWidget {
  final RecallData recall;
  const FdaRecallDetailsPageV2({super.key, required this.recall});

  @override
  State<FdaRecallDetailsPageV2> createState() => _FdaRecallDetailsPageV2State();
}

class _FdaRecallDetailsPageV2State extends State<FdaRecallDetailsPageV2> {
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
      print('🔄 Fetching fresh FDA recalls with forceRefresh=true...');
      final recalls = await RecallDataService().getFdaRecalls(
        forceRefresh: true,
      );
      final id = widget.recall.fdaRecallId;
      print('🔍 Looking for recall with FDA ID: $id');
      final fresh = recalls.firstWhere(
        (r) => r.fdaRecallId == id,
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
            'FDA Recall Details',
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
            'FDA Recall Details',
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
          'FDA Recall Details',
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
              // Recall Number field (above image carousel)
              if (recall.fieldRecallNumber.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A4A5C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Recall Number: ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          recall.fieldRecallNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // Image Carousel
              SharedImageCarousel(
                imageUrls: recall.getAllImageUrls(),
                showIndicators: false,
                height: 220,
                width: double.infinity,
                borderRadius: 18,
              ),
              const SizedBox(height: 18),
              // Recall Title and Classification
              Text(
                recall.productName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // FDA Recall Details Card
              FDARecallDetailsCard(recall: recall),
              const SizedBox(height: 12),
              if (recall.productIdentification.trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A4A5C),
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                        recall.productIdentification,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              if (recall.howFound.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A4A5C),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How Found:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recall.howFound,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              // Accordions
              SharedAdverseReactionsAccordion(
                adverseReactions: recall.adverseReactions,
                adverseReactionDetails: recall.adverseReactionDetails,
              ),
              SharedRecommendationsAccordion(
                recommendationsActions: recall.recommendationsActions,
                remedy: recall.remedy,
              ),
              SharedProductDistributionAccordion(
                productDistribution: recall.productDistribution,
              ),
              SharedManufacturerRetailerAccordion(recall: recall),
              // Recommended Replacement Items Section
              SharedRecommendedProductsAccordion(recall: recall),
              // FDA Resources Section (from original page)
              const SharedFdaResourcesSection(),
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
                      'FDA Recall/Alert Link',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 35),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (recall.pressReleaseLink.isNotEmpty) {
                        final url = Uri.parse(recall.pressReleaseLink);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                    child: const Text(
                      'FDA Recall/Alert Press Release',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 35),
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
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
              // Recall ID and States
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '[FDA Recall ID]',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        recall.fdaRecallId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '[States Affected]',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      recall.stateCount == 0
                          ? const Text(
                              'NATIONWIDE',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            )
                          : Text(
                              '${recall.stateCount} States',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ],
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
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Recalls'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
