import 'package:flutter/material.dart';
import '../../models/recall_data.dart';

class SharedManufacturerRetailerAccordion extends StatefulWidget {
  final RecallData recall;
  const SharedManufacturerRetailerAccordion({required this.recall, super.key});

  @override
  State<SharedManufacturerRetailerAccordion> createState() =>
      _SharedManufacturerRetailerAccordionState();
}

class _SharedManufacturerRetailerAccordionState
    extends State<SharedManufacturerRetailerAccordion> {
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
                  _detailsRow('Name:', r.recallingFdaFirm),
                  _detailsRow('Contact Name:', r.firmContactName),
                  _detailsRow('Contact Phone:', r.firmContactPhone),
                  _detailsRow(
                    'Contact Hours/Days:',
                    r.firmContactBusinessHoursDays,
                  ),
                  _detailsRow('Contact Email:', r.firmContactEmail),
                  _detailsRow('Website:', r.firmContactWebSite),
                  _detailsRow('Website Info:', r.firmWebSiteInfo),
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
