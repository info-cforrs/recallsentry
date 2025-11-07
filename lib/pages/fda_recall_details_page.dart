import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recall_data.dart';
import '../services/recall_data_service.dart';
import '../services/api_service.dart';
import '../widgets/shared/shared_adverse_reactions_accordion.dart';
import '../widgets/shared/shared_recommendations_accordion.dart';
import '../widgets/shared/shared_product_distribution_accordion.dart';
import 'rmc_details_page.dart';
import 'main_navigation.dart';

class FdaRecallDetailsPage extends StatefulWidget {
  final RecallData recall;
  const FdaRecallDetailsPage({super.key, required this.recall});

  @override
  State<FdaRecallDetailsPage> createState() => _FdaRecallDetailsPageState();
}

class _FdaRecallDetailsPageState extends State<FdaRecallDetailsPage> with WidgetsBindingObserver {
  RecallData? _freshRecall;
  bool _isLoading = true;
  String? _error;
  int _refreshKey = 0; // Used to force rebuild of premium widgets after login

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLatestRecall();
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

  Future<void> _fetchLatestRecall() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final recalls = await RecallDataService().getFdaRecalls(
        forceRefresh: true,
      );
      final id = widget.recall.fdaRecallId;
      final fresh = recalls.firstWhere(
        (r) => r.fdaRecallId == id,
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
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3547),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'FDA Recall Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Recall Number Tag at Top (USDA style) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A4A5C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Recall Number: ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _freshRecall?.fieldRecallNumber.isNotEmpty ==
                                        true
                                    ? _freshRecall!.fieldRecallNumber
                                    : 'FDA RECALL',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Top image carousel (USDA style)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          height: 140,
                          width: 240,
                          child: _FdaImageCarousel(
                            imageUrls: [
                              _freshRecall?.imageUrl ?? '',
                              _freshRecall?.imageUrl2 ?? '',
                              _freshRecall?.imageUrl3 ?? '',
                              _freshRecall?.imageUrl4 ?? '',
                              _freshRecall?.imageUrl5 ?? '',
                            ].where((url) => url.isNotEmpty).toList(),
                            showIndicators: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // FDA Recall ID field below carousel
                    if (_freshRecall?.fdaRecallId != null &&
                        _freshRecall!.fdaRecallId.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'FDA Recall ID: ${_freshRecall!.fdaRecallId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    // Details card
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A4A5C),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Brand:', _freshRecall?.brandName ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Category:', _freshRecall?.category ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Date Issued:', _freshRecall?.dateIssued != null ? _formatDate(_freshRecall!.dateIssued) : 'N/A'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Classification:', _freshRecall?.recallClassification ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Start Recall Process button
                    _buildStartRecallProcessButton(context, _freshRecall!),
                    const SizedBox(height: 16),
                    // PRODUCT IDENTIFICATION section (placeholder for FDA)
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
                            _freshRecall?.productIdentification.isNotEmpty ==
                                    true
                                ? _freshRecall!.productIdentification
                                : '[Not specified for FDA]',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // RECALL PHA REASON section (placeholder for FDA)
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
                            _freshRecall?.recallPhaReason.isNotEmpty == true
                                ? _freshRecall!.recallPhaReason
                                : '[Not specified for FDA]',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // HOW FOUND section (new)
                    if (_freshRecall?.howFound != null &&
                        _freshRecall!.howFound.trim().isNotEmpty)
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
                              'How Found:',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _freshRecall!.howFound,
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
                      adverseReactions: _freshRecall?.adverseReactions ?? '',
                      adverseReactionDetails:
                          _freshRecall?.adverseReactionDetails ?? '',
                    ),
                    // --- Recommendations Accordion Section (Premium) ---
                    SharedRecommendationsAccordion(
                      key: ValueKey('recommendations_$_refreshKey'),
                      recommendationsActions:
                          _freshRecall?.recommendationsActions ?? '',
                      remedy: _freshRecall?.remedy ?? '',
                    ),
                    // --- Product Distribution Accordion Section (Premium) ---
                    SharedProductDistributionAccordion(
                      key: ValueKey('product_distribution_$_refreshKey'),
                      productDistribution:
                          _freshRecall?.productDistribution ?? '',
                    ),
                    // --- Manufacturer and Retailer Details Accordion Section (placeholder for FDA) ---
                    _ManufacturerRetailerAccordion(recall: _freshRecall!),
                    // --- FDA Resources Section ---
                    const SizedBox(height: 8),
                    _FdaResourcesSection(recall: _freshRecall!),
                    // --- Bottom Big Button Section ---
                    const SizedBox(height: 24),
                    _BottomBigButtonSection(
                      recallUrl: _freshRecall?.recallUrl ?? '',
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C3E50),
        selectedItemColor: const Color(0xFF64B5F6),
        unselectedItemColor: Colors.white54,
        currentIndex: 1,
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
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
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
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

// --- FDA Image Carousel Widget ---
class _FdaImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final bool showIndicators;
  const _FdaImageCarousel({
    required this.imageUrls,
    this.showIndicators = false,
  });

  @override
  State<_FdaImageCarousel> createState() => _FdaImageCarouselState();
}

class _FdaImageCarouselState extends State<_FdaImageCarousel> {
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

    return SizedBox(
      height: 140,
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
                icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 32),
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
          if (widget.showIndicators && imageUrls.length > 1)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
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
      ),
    );
  }
}

// --- Accordions and Sections ---
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
                      'Manufacturer & Retailer Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
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
                  Text(
                    'Manufacturer: ${r.recallingFdaFirm.isNotEmpty ? r.recallingFdaFirm : '[Not specified for FDA]'}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  Text(
                    'Contact Name: ${r.firmContactName.isNotEmpty ? r.firmContactName : '[Not specified]'}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  Text(
                    'Contact Phone: ${r.firmContactPhone.isNotEmpty ? r.firmContactPhone : '[Not specified]'}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  Text(
                    'Contact Email: ${r.firmContactEmail.isNotEmpty ? r.firmContactEmail : '[Not specified]'}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  Text(
                    'Website: ${r.firmContactWebSite.isNotEmpty ? r.firmContactWebSite : '[Not specified]'}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// --- FDA Resources Section ---
class _FdaResourcesSection extends StatelessWidget {
  final RecallData recall;
  const _FdaResourcesSection({required this.recall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'FDA Resources',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (recall.firmContactPhone.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.white),
              title: Text(
                'Contact: ${recall.firmContactPhone}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (recall.recallUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text(
                'Recall Link',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                final url = Uri.parse(recall.recallUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
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
        // Top blue button
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
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
            'FDA Recall/Alert Link',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 18,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        // Bottom subscribe button
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
