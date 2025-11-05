import 'package:flutter/material.dart';
import '../widgets/USDA_Recall_Details_Card.dart';
import '../models/recall_data.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/shared/shared_usda_resources_section.dart';
import '../widgets/shared/shared_adverse_reactions_accordion.dart';
import '../widgets/shared/shared_recommendations_accordion.dart';
import '../widgets/shared/shared_product_distribution_accordion.dart';
import 'main_navigation.dart';

// --- Image Carousel Widget ---
class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final bool showIndicators;
  const _ImageCarousel({required this.imageUrls, this.showIndicators = false});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.imageUrls;
    if (imageUrls.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          size: 80,
          color: Colors.grey[400],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 240,
          width: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _FullScreenImageView(imageUrl: url),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (imageUrls.length > 1 && _currentPage > 0)
                Positioned(
                  left: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      if (_currentPage > 0) {
                        _controller.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              if (imageUrls.length > 1 && _currentPage < imageUrls.length - 1)
                Positioned(
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      if (_currentPage < imageUrls.length - 1) {
                        _controller.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        if (widget.showIndicators && imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class UsdaRecallDetailsPage extends StatefulWidget {
  final RecallData recall;
  const UsdaRecallDetailsPage({super.key, required this.recall});

  @override
  State<UsdaRecallDetailsPage> createState() => _UsdaRecallDetailsPageState();
}

class _UsdaRecallDetailsPageState extends State<UsdaRecallDetailsPage> with WidgetsBindingObserver {
  int _refreshKey = 0; // Used to force rebuild of premium widgets after login

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes (e.g., after login modal), refresh premium status
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _refreshKey++; // Increment key to force rebuild of premium widgets
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3547),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'USDA Recall Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Recall Number Tag at Top ---
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A4A5C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Recall Number: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          widget.recall.fieldRecallNumber.isNotEmpty
                              ? widget.recall.fieldRecallNumber
                              : 'Not specified',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.error, color: Colors.red, size: 24),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Top image carousel
              SizedBox(
                height: 280,
                width: 280,
                child: _ImageCarousel(
                  imageUrls: [
                    widget.recall.imageUrl,
                    widget.recall.imageUrl2,
                    widget.recall.imageUrl3,
                    widget.recall.imageUrl4,
                    widget.recall.imageUrl5,
                  ].where((url) => url.isNotEmpty).toList(),
                  showIndicators: true,
                ),
              ),
              const SizedBox(height: 16),
              // Top text fields (ID, etc.)
              Center(
                child: Text(
                  'USDA Recall ID: ${widget.recall.usdaRecallId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Details card
              USDARecallDetailsCard(recall: widget.recall),
              const SizedBox(height: 16),
              // Start Recall Process button (always visible)
              _buildStartRecallProcessButton(context),
              const SizedBox(height: 16),
              // PRODUCT IDENTIFICATION section
              if (widget.recall.productIdentification.isNotEmpty)
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
                      Text(
                        'Product Identification:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.recall.productIdentification,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              // RECALL PHA REASON section
              if (widget.recall.recallPhaReason.isNotEmpty)
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
                      Text(
                        'Reason for Recall:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.recall.recallPhaReason,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              // PRODUCT IDENTIFICATION section
              if (widget.recall.productIdentification.isNotEmpty)
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
                      Text(
                        'Product Identification:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.recall.productIdentification,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              // --- Adverse Reactions Accordion Section (Premium) ---
              SharedAdverseReactionsAccordion(
                key: ValueKey('adverse_reactions_$_refreshKey'),
                adverseReactions: widget.recall.adverseReactions,
                adverseReactionDetails: widget.recall.adverseReactionDetails,
              ),
              // --- Recommendations Accordion Section (Premium) ---
              SharedRecommendationsAccordion(
                key: ValueKey('recommendations_$_refreshKey'),
                recommendationsActions: widget.recall.recommendationsActions,
                remedy: widget.recall.remedy,
              ),
              // --- Product Distribution Accordion Section (Premium) ---
              SharedProductDistributionAccordion(
                key: ValueKey('product_distribution_$_refreshKey'),
                productDistribution: widget.recall.productDistribution,
              ),
              // --- Manufacturer and Retailer Details Accordion Section ---
              _ManufacturerRetailerAccordion(recall: widget.recall),
              // --- USDA Resources Section ---
              const SizedBox(height: 8),
              SharedUsdaResourcesSection(),
              // --- Bottom Big Button Section ---
              const SizedBox(height: 24),
              _BottomBigButtonSection(recallUrl: widget.recall.recallUrl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigation(initialIndex: 0),
              ),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigation(initialIndex: 1),
              ),
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigation(initialIndex: 2),
              ),
              (route) => false,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Info'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        backgroundColor: Color(0xFF2C3E50),
        selectedItemColor: Color(0xFF64B5F6),
        unselectedItemColor: Colors.white54,
        elevation: 8,
        selectedFontSize: 14,
        unselectedFontSize: 12,
      ),
    );
  }

  Widget _buildStartRecallProcessButton(BuildContext context) {
    final bool isNotStarted = widget.recall.recallResolutionStatus == 'Not Started';
    final String statusText = isNotStarted
        ? 'Start Recall Process'
        : 'Recall Started: ${widget.recall.recallResolutionStatus}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isNotStarted ? () {
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
                      onPressed: () {
                        // TODO: Update recall status in backend
                        // For now, we'll update the local state
                        setState(() {
                          // This will need to be properly implemented with a service call
                          // to update the backend and refresh the data
                        });

                        Navigator.of(context).pop();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recall Management Center activated!'),
                            backgroundColor: Color(0xFF4CAF50),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        // TODO: Navigate to Recall Management Center page
                        // Navigator.of(context).pushNamed('/usda-rmc', arguments: widget.recall);
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
          } : () {
            // If already started, navigate to RMC page
            // TODO: Navigate to Recall Management Center page
            // Navigator.of(context).pushNamed('/usda-rmc', arguments: widget.recall);
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
                        isNotStarted
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
  }

  // (removed unused _detailsRowBlack helper)
}

// --- Manufacturer and Retailer Details Accordion Widget ---
class _ManufacturerRetailerAccordion extends StatefulWidget {
  final RecallData recall;
  const _ManufacturerRetailerAccordion({required this.recall});

  @override
  State<_ManufacturerRetailerAccordion> createState() =>
      _ManufacturerRetailerAccordionState();
}

class _ManufacturerRetailerAccordionState
    extends State<_ManufacturerRetailerAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.recall;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manufacturer and Retailer Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.remove : Icons.add,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manufacturer Section
                  Text(
                    'Manufacturer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailsRow('Name:', r.establishmentManufacturer),
                  _detailsRow(
                    'Contact Name:',
                    r.establishmentManufacturerContactName,
                  ),
                  _detailsRow(
                    'Contact Phone:',
                    r.establishmentManufacturerContactPhone,
                  ),
                  _detailsRow(
                    'Contact Hours/Days:',
                    r.establishmentManufacturerContactBusinessHoursDays,
                  ),
                  _detailsRow(
                    'Contact Email:',
                    r.establishmentManufacturerContactEmail,
                  ),
                  _detailsRow('Website:', r.establishmentManufacturerWebsite),
                  _detailsRow(
                    'Website Info:',
                    r.establishmentManufacturerWebsiteInfo,
                  ),
                  const SizedBox(height: 38),
                  // Retailer Section
                  Text(
                    'Retailer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailsRow('Retailer Name:', r.retailer1),
                  _detailsRow('Sale Date Start:', r.retailer1SaleDateStart),
                  _detailsRow('Sale Date End:', r.retailer1SaleDateEnd),
                  _detailsRow('Contact Name:', r.retailer1ContactName),
                  _detailsRow('Contact Phone:', r.retailer1ContactPhone),
                  _detailsRow(
                    'Contact Hours/Days:',
                    r.retailer1ContactBusinessHoursDays,
                  ),
                  _detailsRow('Contact Email:', r.retailer1ContactEmail),
                  _detailsRow('Website:', r.retailer1ContactWebSite),
                  _detailsRow('Website Info:', r.retailer1WebSiteInfo),
                  _detailsRow('Est. Item Value:', r.estItemValue),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not specified',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Bottom Big Button Section Widget ---
class _BottomBigButtonSection extends StatelessWidget {
  final String recallUrl;
  const _BottomBigButtonSection({required this.recallUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top orange button
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFEC7A2D),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            if (recallUrl.isNotEmpty) {
              final url = Uri.parse(recallUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: const Text(
            'USDA Recall/Alert Link',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 18,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        // Bottom blue button
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
    );
  }
}

// --- Full Screen Image View Widget ---
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.broken_image,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
