import 'package:flutter/material.dart';
import '../../models/recall_data.dart';

class SharedManufacturerRetailerAccordion extends StatelessWidget {
  final RecallData recall;
  const SharedManufacturerRetailerAccordion({required this.recall, super.key});

  @override
  Widget build(BuildContext context) {
    final r = recall;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            const Text(
              'Manufacturer and Retailer Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            // Manufacturer Section
            const Text(
              'Manufacturer',
              style: TextStyle(
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
            _detailsRow(
              'Contact Form:',
              r.establishmentManufacturerContactForm,
            ),
            _detailsRow('Website:', r.establishmentManufacturerWebsite),
            _detailsRow(
              'Website Info:',
              r.establishmentManufacturerWebsiteInfo,
            ),
            const SizedBox(height: 38),
            // Retailer Section
            const Text(
              'Retailer',
              style: TextStyle(
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
