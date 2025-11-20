import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recall_data.dart';
import 'main_navigation.dart';

class ManufacturerRetailerPage extends StatelessWidget {
  final RecallData recall;

  const ManufacturerRetailerPage({super.key, required this.recall});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is an FDA recall
    final bool isFDA = recall.agency.toUpperCase() == 'FDA';

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
                      if (recall.recallingFdaFirm.isNotEmpty)
                        _buildRow('Recalling Firm:', recall.recallingFdaFirm),

                      // Firm Contact Name
                      if (recall.firmContactName.isNotEmpty)
                        _buildRow('Contact Name:', recall.firmContactName),

                      // Firm Contact Phone
                      if (recall.firmContactPhone.isNotEmpty)
                        _buildClickableRow(
                          'Phone:',
                          recall.firmContactPhone,
                          'tel:${recall.firmContactPhone}',
                        ),

                      // Firm Contact Email
                      if (recall.firmContactEmail.isNotEmpty)
                        _buildClickableRow(
                          'Email:',
                          recall.firmContactEmail,
                          'mailto:${recall.firmContactEmail}',
                        ),

                      // Firm Contact Business Hours
                      if (recall.firmContactBusinessHoursDays.isNotEmpty)
                        _buildRow(
                          'Business Hours:',
                          recall.firmContactBusinessHoursDays,
                        ),

                      // Firm Contact Website
                      if (recall.firmContactWebSite.isNotEmpty)
                        _buildClickableRow(
                          'Website:',
                          recall.firmContactWebSite,
                          recall.firmContactWebSite.startsWith('http')
                              ? recall.firmContactWebSite
                              : 'https://${recall.firmContactWebSite}',
                        ),

                      // Firm Website Info
                      if (recall.firmWebSiteInfo.isNotEmpty)
                        _buildRow('Website Info:', recall.firmWebSiteInfo),

                      // Firm Contact Form
                      if (recall.firmContactForm.isNotEmpty)
                        _buildClickableRow(
                          'Contact Form:',
                          'Submit Contact Form',
                          recall.firmContactForm.startsWith('http')
                              ? recall.firmContactForm
                              : 'https://${recall.firmContactForm}',
                        ),
                    ] else ...[
                      // USDA Establishment Fields
                      // Row 1: Name
                      if (recall.establishmentManufacturer.isNotEmpty)
                        _buildRow('Name:', recall.establishmentManufacturer),

                      // Row 3: Contact
                      if (recall.establishmentManufacturerContactName.isNotEmpty)
                        _buildRow('Contact:', recall.establishmentManufacturerContactName),

                      // Row 4: Phone
                      if (recall.establishmentManufacturerContactPhone.isNotEmpty)
                        _buildClickableRow(
                          'Phone:',
                          recall.establishmentManufacturerContactPhone,
                          'tel:${recall.establishmentManufacturerContactPhone}',
                        ),

                      // Row 5: Business Hours
                      if (recall.establishmentManufacturerContactBusinessHoursDays.isNotEmpty)
                        _buildRow(
                          'Business Hours:',
                          recall.establishmentManufacturerContactBusinessHoursDays,
                        ),

                      // Row 6: Email
                      if (recall.establishmentManufacturerContactEmail.isNotEmpty)
                        _buildClickableRow(
                          'Email:',
                          recall.establishmentManufacturerContactEmail,
                          'mailto:${recall.establishmentManufacturerContactEmail}',
                        ),

                      // Row 7: Website
                      if (recall.establishmentManufacturerWebsite.isNotEmpty)
                        _buildClickableRow(
                          'Website:',
                          recall.establishmentManufacturerWebsite,
                          recall.establishmentManufacturerWebsite.startsWith('http')
                              ? recall.establishmentManufacturerWebsite
                              : 'https://${recall.establishmentManufacturerWebsite}',
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
                      if (recall.retailer1.isNotEmpty)
                        _buildRow('Name:', recall.retailer1),

                      // Retailer Contact
                      if (recall.retailer1ContactName.isNotEmpty)
                        _buildRow('Contact:', recall.retailer1ContactName),

                      // Retailer Phone
                      if (recall.retailer1ContactPhone.isNotEmpty)
                        _buildClickableRow(
                          'Phone:',
                          recall.retailer1ContactPhone,
                          'tel:${recall.retailer1ContactPhone}',
                        ),

                      // Retailer Business Hours
                      if (recall.retailer1ContactBusinessHoursDays.isNotEmpty)
                        _buildRow(
                          'Business Hours:',
                          recall.retailer1ContactBusinessHoursDays,
                        ),

                      // Retailer Email
                      if (recall.retailer1ContactEmail.isNotEmpty)
                        _buildClickableRow(
                          'Email:',
                          recall.retailer1ContactEmail,
                          'mailto:${recall.retailer1ContactEmail}',
                        ),

                      // Retailer Website
                      if (recall.retailer1ContactWebSite.isNotEmpty)
                        _buildClickableRow(
                          'Website:',
                          recall.retailer1ContactWebSite,
                          recall.retailer1ContactWebSite.startsWith('http')
                              ? recall.retailer1ContactWebSite
                              : 'https://${recall.retailer1ContactWebSite}',
                        ),
                    ],

                    // No data message
                    if (isFDA
                        ? (recall.recallingFdaFirm.isEmpty &&
                            recall.firmContactName.isEmpty &&
                            recall.firmContactPhone.isEmpty &&
                            recall.firmContactEmail.isEmpty &&
                            recall.firmContactBusinessHoursDays.isEmpty &&
                            recall.firmContactWebSite.isEmpty &&
                            recall.firmWebSiteInfo.isEmpty &&
                            recall.firmContactForm.isEmpty)
                        : (recall.establishmentManufacturer.isEmpty &&
                            recall.establishmentManufacturerContactName.isEmpty &&
                            recall.establishmentManufacturerContactPhone.isEmpty &&
                            recall.establishmentManufacturerContactBusinessHoursDays.isEmpty &&
                            recall.establishmentManufacturerContactEmail.isEmpty &&
                            recall.establishmentManufacturerWebsite.isEmpty &&
                            recall.retailer1.isEmpty &&
                            recall.retailer1ContactName.isEmpty &&
                            recall.retailer1ContactPhone.isEmpty &&
                            recall.retailer1ContactBusinessHoursDays.isEmpty &&
                            recall.retailer1ContactEmail.isEmpty &&
                            recall.retailer1ContactWebSite.isEmpty))
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
