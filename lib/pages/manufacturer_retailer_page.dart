import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recall_data.dart';
import 'main_navigation.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';

class ManufacturerRetailerPage extends StatefulWidget {
  final RecallData recall;

  const ManufacturerRetailerPage({super.key, required this.recall});

  @override
  State<ManufacturerRetailerPage> createState() => _ManufacturerRetailerPageState();
}

class _ManufacturerRetailerPageState extends State<ManufacturerRetailerPage> with HideOnScrollMixin {
  @override
  void initState() {
    super.initState();
    initHideOnScroll();
  }

  @override
  void dispose() {
    disposeHideOnScroll();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is an FDA recall
    final bool isFDA = widget.recall.agency.toUpperCase() == 'FDA';

    return Scaffold(
      backgroundColor: const Color(0xFF2A4A5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A4A5C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isFDA ? 'Firm Contact' : 'Manufacturer & Retailer',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: hideOnScrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Manufacturer/Firm Section Title
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D3547),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.factory,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isFDA ? 'Firm Contact' : 'Manufacturer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // FDA Firm Contact Fields
                    if (isFDA) ...[
                      // Recalling Firm
                      if (widget.recall.recallingFdaFirm.isNotEmpty)
                        _buildRow('Recalling Firm:', widget.recall.recallingFdaFirm),

                      // Firm Contact Name
                      if (widget.recall.firmContactName.isNotEmpty)
                        _buildRow('Contact Name:', widget.recall.firmContactName),

                      // Firm Contact Phone
                      if (widget.recall.firmContactPhone.isNotEmpty)
                        _buildClickableRow(
                          'Phone:',
                          widget.recall.firmContactPhone,
                          'tel:${widget.recall.firmContactPhone}',
                        ),

                      // Firm Contact Email
                      if (widget.recall.firmContactEmail.isNotEmpty)
                        _buildClickableRow(
                          'Email:',
                          widget.recall.firmContactEmail,
                          'mailto:${widget.recall.firmContactEmail}',
                        ),

                      // Firm Contact Business Hours
                      if (widget.recall.firmContactBusinessHoursDays.isNotEmpty)
                        _buildRow(
                          'Business Hours:',
                          widget.recall.firmContactBusinessHoursDays,
                        ),

                      // Firm Contact Website
                      if (widget.recall.firmContactWebSite.isNotEmpty)
                        _buildClickableRow(
                          'Website:',
                          widget.recall.firmContactWebSite,
                          widget.recall.firmContactWebSite.startsWith('http')
                              ? widget.recall.firmContactWebSite
                              : 'https://${widget.recall.firmContactWebSite}',
                        ),

                      // Firm Website Info
                      if (widget.recall.firmWebSiteInfo.isNotEmpty)
                        _buildRow('Website Info:', widget.recall.firmWebSiteInfo),

                      // Firm Contact Form
                      if (widget.recall.firmContactForm.isNotEmpty)
                        _buildClickableRow(
                          'Contact Form:',
                          'Submit Contact Form',
                          widget.recall.firmContactForm.startsWith('http')
                              ? widget.recall.firmContactForm
                              : 'https://${widget.recall.firmContactForm}',
                        ),
                    ] else ...[
                      // USDA Establishment Fields
                      // Row 1: Name
                      if (widget.recall.establishmentManufacturer.isNotEmpty)
                        _buildRow('Name:', widget.recall.establishmentManufacturer),

                      // Row 3: Contact
                      if (widget.recall.establishmentManufacturerContactName.isNotEmpty)
                        _buildRow('Contact:', widget.recall.establishmentManufacturerContactName),

                      // Row 4: Phone
                      if (widget.recall.establishmentManufacturerContactPhone.isNotEmpty)
                        _buildClickableRow(
                          'Phone:',
                          widget.recall.establishmentManufacturerContactPhone,
                          'tel:${widget.recall.establishmentManufacturerContactPhone}',
                        ),

                      // Row 5: Business Hours
                      if (widget.recall.establishmentManufacturerContactBusinessHoursDays.isNotEmpty)
                        _buildRow(
                          'Business Hours:',
                          widget.recall.establishmentManufacturerContactBusinessHoursDays,
                        ),

                      // Row 6: Email
                      if (widget.recall.establishmentManufacturerContactEmail.isNotEmpty)
                        _buildClickableRow(
                          'Email:',
                          widget.recall.establishmentManufacturerContactEmail,
                          'mailto:${widget.recall.establishmentManufacturerContactEmail}',
                        ),

                      // Row 7: Website
                      if (widget.recall.establishmentManufacturerWebsite.isNotEmpty)
                        _buildClickableRow(
                          'Website:',
                          widget.recall.establishmentManufacturerWebsite,
                          widget.recall.establishmentManufacturerWebsite.startsWith('http')
                              ? widget.recall.establishmentManufacturerWebsite
                              : 'https://${widget.recall.establishmentManufacturerWebsite}',
                        ),
                    ],

                    // Retailer Section (USDA only)
                    if (!isFDA) ...[
                      // Spacer
                      const SizedBox(height: 32),
                      const Divider(color: Colors.white24, thickness: 1),
                      const SizedBox(height: 32),

                      // Retailer Section Title
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D3547),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.storefront,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Retailer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Retailer Name
                      if (widget.recall.retailer1.isNotEmpty)
                        _buildRow('Name:', widget.recall.retailer1),

                      // Retailer Sale Date Start
                      if (widget.recall.retailer1SaleDateStart.isNotEmpty)
                        _buildRow('Sale Date Start:', widget.recall.retailer1SaleDateStart),

                      // Retailer Sale Date End
                      if (widget.recall.retailer1SaleDateEnd.isNotEmpty)
                        _buildRow('Sale Date End:', widget.recall.retailer1SaleDateEnd),

                      // Retailer Contact
                      if (widget.recall.retailer1ContactName.isNotEmpty)
                        _buildRow('Contact:', widget.recall.retailer1ContactName),

                      // Retailer Phone
                      if (widget.recall.retailer1ContactPhone.isNotEmpty)
                        _buildClickableRow(
                          'Phone:',
                          widget.recall.retailer1ContactPhone,
                          'tel:${widget.recall.retailer1ContactPhone}',
                        ),

                      // Retailer Business Hours
                      if (widget.recall.retailer1ContactBusinessHoursDays.isNotEmpty)
                        _buildRow(
                          'Business Hours:',
                          widget.recall.retailer1ContactBusinessHoursDays,
                        ),

                      // Retailer Email
                      if (widget.recall.retailer1ContactEmail.isNotEmpty)
                        _buildClickableRow(
                          'Email:',
                          widget.recall.retailer1ContactEmail,
                          'mailto:${widget.recall.retailer1ContactEmail}',
                        ),

                      // Retailer Website
                      if (widget.recall.retailer1ContactWebSite.isNotEmpty)
                        _buildClickableRow(
                          'Website:',
                          widget.recall.retailer1ContactWebSite,
                          widget.recall.retailer1ContactWebSite.startsWith('http')
                              ? widget.recall.retailer1ContactWebSite
                              : 'https://${widget.recall.retailer1ContactWebSite}',
                        ),

                      // Retailer Website Info
                      if (widget.recall.retailer1WebSiteInfo.isNotEmpty)
                        _buildRow('Website Info:', widget.recall.retailer1WebSiteInfo),
                    ],

                    // No data message
                    if (isFDA
                        ? (widget.recall.recallingFdaFirm.isEmpty &&
                            widget.recall.firmContactName.isEmpty &&
                            widget.recall.firmContactPhone.isEmpty &&
                            widget.recall.firmContactEmail.isEmpty &&
                            widget.recall.firmContactBusinessHoursDays.isEmpty &&
                            widget.recall.firmContactWebSite.isEmpty &&
                            widget.recall.firmWebSiteInfo.isEmpty &&
                            widget.recall.firmContactForm.isEmpty)
                        : (widget.recall.establishmentManufacturer.isEmpty &&
                            widget.recall.establishmentManufacturerContactName.isEmpty &&
                            widget.recall.establishmentManufacturerContactPhone.isEmpty &&
                            widget.recall.establishmentManufacturerContactBusinessHoursDays.isEmpty &&
                            widget.recall.establishmentManufacturerContactEmail.isEmpty &&
                            widget.recall.establishmentManufacturerWebsite.isEmpty &&
                            widget.recall.retailer1.isEmpty &&
                            widget.recall.retailer1SaleDateStart.isEmpty &&
                            widget.recall.retailer1SaleDateEnd.isEmpty &&
                            widget.recall.retailer1ContactName.isEmpty &&
                            widget.recall.retailer1ContactPhone.isEmpty &&
                            widget.recall.retailer1ContactBusinessHoursDays.isEmpty &&
                            widget.recall.retailer1ContactEmail.isEmpty &&
                            widget.recall.retailer1ContactWebSite.isEmpty &&
                            widget.recall.retailer1WebSiteInfo.isEmpty))
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            Icon(
                              Icons.info_outline,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isFDA
                                  ? 'No firm contact details available.'
                                  : 'No manufacturer or retailer details available.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
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
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3547),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Label (left-aligned)
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right column: Value (right-aligned)
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableRow(String label, String value, String url) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3547),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Label (left-aligned)
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right column: Clickable Value (right-aligned)
          Expanded(
            child: GestureDetector(
              onTap: () => _launchUrl(url),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
