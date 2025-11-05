import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recall_data.dart';
import '../services/api_service.dart';
import '../widgets/usda_rmc_status_card.dart';
import '../widgets/usda_return_item_accordion.dart';
import '../widgets/usda_replace_item_accordion.dart';
import '../widgets/usda_repair_item_accordion.dart';
import '../widgets/usda_dispose_item_accordion.dart';

class RmcDetailsPage extends StatefulWidget {
  final RecallData recall;

  const RmcDetailsPage({
    super.key,
    required this.recall,
  });

  @override
  State<RmcDetailsPage> createState() => _RmcDetailsPageState();
}

class _RmcDetailsPageState extends State<RmcDetailsPage> {
  late RecallData _recall;
  bool _isUpdating = false;
  String? _lockedAccordion; // Track which accordion is locked: 'return', 'replace', 'repair', 'dispose', or null
  String? _expandedAccordion; // Track which accordion is expanded: 'return', 'replace', 'repair', 'dispose', or null

  @override
  void initState() {
    super.initState();
    _recall = widget.recall;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await ApiService().updateRecallStatus(_recall, newStatus);
      // Refresh the recall data
      await _refreshRecallData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _refreshRecallData() async {
    try {
      // Fetch the updated recall data from the API using databaseId
      if (_recall.databaseId != null) {
        final updatedRecall = await ApiService().fetchRecallById(_recall.databaseId!);
        if (mounted) {
          setState(() {
            _recall = updatedRecall;

            // Auto-lock and keep expanded if flow is completed
            final status = _recall.recallResolutionStatus;

            // Return flow completed
            if (status == 'Return 2: Received Refund') {
              if (_lockedAccordion != 'return') {
                _lockedAccordion = 'return';
              }
              _expandedAccordion = 'return';
            }
            // Replace flow completed
            else if (status == 'Replace 1A: Received Parts' ||
                     status == 'Replace 2A: Received Replacement Item') {
              if (_lockedAccordion != 'replace') {
                _lockedAccordion = 'replace';
              }
              _expandedAccordion = 'replace';
            }
            // Repair flow completed
            else if (status == 'Repair 1B: Item Repaired by Service Center' ||
                     status == 'Repair 2B: Item Repaired by User') {
              if (_lockedAccordion != 'repair') {
                _lockedAccordion = 'repair';
              }
              _expandedAccordion = 'repair';
            }
            // Dispose flow completed
            else if (status == 'Dispose 1B: Received Refund' ||
                     status == 'Dispose 2A: Disposed of Item') {
              if (_lockedAccordion != 'dispose') {
                _lockedAccordion = 'dispose';
              }
              _expandedAccordion = 'dispose';
            }
          });
        }
      } else {
        print('Warning: Recall has no databaseId, cannot refresh');
      }
    } catch (e) {
      print('Error refreshing recall data: $e');
    }
  }

  // Helper method to check if Section 1 is completed
  bool _isSection1Completed() {
    final status = _recall.recallResolutionStatus;
    // Section 1 is completed if status is anything beyond "Open"
    return status != 'Not Started' && status != 'Open';
  }

  // Helper method to check if Section 3 is completed
  bool _isSection3Completed() {
    final status = _recall.recallResolutionStatus;
    // Section 3 is completed if any resolution path is fully completed
    return status == 'Return 2: Received Refund' ||
        status == 'Replace 1A: Received Parts' ||
        status == 'Replace 2A: Received Replacement Item' ||
        status == 'Repair 1B: Item Repaired by Service Center' ||
        status == 'Repair 2B: Item Repaired by User' ||
        status == 'Dispose 1B: Received Refund' ||
        status == 'Dispose 2A: Disposed of Item' ||
        status == 'Completed';
  }

  // Helper method to check if Section 4 is completed
  bool _isSection4Completed() {
    return _recall.recallResolutionStatus == 'Completed';
  }

  // Helper method to check if recall is completed (locked for editing)
  bool _isRecallCompleted() {
    return _recall.recallResolutionStatus == 'Completed';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWebsite(String url) async {
    // Ensure URL has a scheme
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }

    final Uri webUri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open website'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFC107),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Recall Management Center Detail',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recall ID Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF34495E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"Recall ID: " [${_recall.usdaRecallId.isNotEmpty ? _recall.usdaRecallId : _recall.fdaRecallId}]',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            Text(
              _recall.productName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // USDA RMC Status Card (Yellow Box)
            USDARmcStatusCard(recall: _recall),

            const SizedBox(height: 16),

            // Recall Management Center - Combined Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5F7A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Section Title
                  const Text(
                    'Recall Management Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 1: Discontinue using the Product
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step number circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Step text
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Discontinue using the Product',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Item Use Discontinued Button
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                      onPressed: (_isUpdating || _isRecallCompleted())
                          ? null
                          : () {
                              _updateStatus('Stopped Using');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _isSection1Completed()
                                ? const Icon(
                                    Icons.check,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Item Use Discontinued',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_isUpdating) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Step 2: Contact Manufacturer for Instructions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step number circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Step text
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact Manufacturer for Instructions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '(Phone or Email)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Phone Button (always shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.75,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                        onPressed: (_recall.establishmentManufacturerContactPhone.isNotEmpty && !_isRecallCompleted())
                            ? () {
                                _makePhoneCall(
                                    _recall.establishmentManufacturerContactPhone);
                                _updateStatus('Mfr Contacted');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64B5F6),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.phone, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _recall.establishmentManufacturerContactPhone.isNotEmpty
                                    ? 'Call ${_recall.establishmentManufacturerContactPhone}'
                                    : 'Phone Not Available',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Email Button (always shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.75,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                        onPressed: (_recall.establishmentManufacturerContactEmail.isNotEmpty && !_isRecallCompleted())
                            ? () {
                                _sendEmail(
                                    _recall.establishmentManufacturerContactEmail);
                                _updateStatus('Mfr Contacted');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64B5F6),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.email, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _recall.establishmentManufacturerContactEmail.isNotEmpty
                                    ? 'Email Manufacturer\nor Retailer'
                                    : 'Email Not Available',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Website Button (always shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.75,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                        onPressed: (_recall.establishmentManufacturerWebsite.isNotEmpty && !_isRecallCompleted())
                            ? () {
                                _openWebsite(
                                    _recall.establishmentManufacturerWebsite);
                                _updateStatus('Mfr Contacted');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64B5F6),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.language, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _recall.establishmentManufacturerWebsite.isNotEmpty
                                    ? 'Register and Check Item on Manuf. Web Site'
                                    : 'Website Not Available',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Resolution Type Selection Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Step number circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isSection3Completed()
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFA726),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Section title
                      const Expanded(
                        child: Text(
                          'Select Resolution per Manufacturer or Retailer and follow steps',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Resolution Type Accordions
                  UsdaReturnItemAccordion(
                    key: const ValueKey('return'),
                    recall: _recall,
                    onStatusUpdated: _refreshRecallData,
                    isLocked: _lockedAccordion == 'return',
                    isDisabled: _isRecallCompleted() || (_lockedAccordion != null && _lockedAccordion != 'return'),
                    isExpanded: _expandedAccordion == 'return',
                    onLockToggle: (bool shouldLock) {
                      setState(() {
                        _lockedAccordion = shouldLock ? 'return' : null;
                      });
                    },
                    onExpandToggle: (bool shouldExpand) {
                      setState(() {
                        _expandedAccordion = shouldExpand ? 'return' : null;
                      });
                    },
                  ),
                  UsdaReplaceItemAccordion(
                    key: const ValueKey('replace'),
                    recall: _recall,
                    onStatusUpdated: _refreshRecallData,
                    isLocked: _lockedAccordion == 'replace',
                    isDisabled: _isRecallCompleted() || (_lockedAccordion != null && _lockedAccordion != 'replace'),
                    isExpanded: _expandedAccordion == 'replace',
                    onLockToggle: (bool shouldLock) {
                      setState(() {
                        _lockedAccordion = shouldLock ? 'replace' : null;
                      });
                    },
                    onExpandToggle: (bool shouldExpand) {
                      setState(() {
                        _expandedAccordion = shouldExpand ? 'replace' : null;
                      });
                    },
                  ),
                  UsdaRepairItemAccordion(
                    key: const ValueKey('repair'),
                    recall: _recall,
                    onStatusUpdated: _refreshRecallData,
                    isLocked: _lockedAccordion == 'repair',
                    isDisabled: _isRecallCompleted() || (_lockedAccordion != null && _lockedAccordion != 'repair'),
                    isExpanded: _expandedAccordion == 'repair',
                    onLockToggle: (bool shouldLock) {
                      setState(() {
                        _lockedAccordion = shouldLock ? 'repair' : null;
                      });
                    },
                    onExpandToggle: (bool shouldExpand) {
                      setState(() {
                        _expandedAccordion = shouldExpand ? 'repair' : null;
                      });
                    },
                  ),
                  UsdaDisposeItemAccordion(
                    key: const ValueKey('dispose'),
                    recall: _recall,
                    onStatusUpdated: _refreshRecallData,
                    isLocked: _lockedAccordion == 'dispose',
                    isDisabled: _isRecallCompleted() || (_lockedAccordion != null && _lockedAccordion != 'dispose'),
                    isExpanded: _expandedAccordion == 'dispose',
                    onLockToggle: (bool shouldLock) {
                      setState(() {
                        _lockedAccordion = shouldLock ? 'dispose' : null;
                      });
                    },
                    onExpandToggle: (bool shouldExpand) {
                      setState(() {
                        _expandedAccordion = shouldExpand ? 'dispose' : null;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section 4: Close Recall Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step number circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isSection4Completed()
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFA726),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '4',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Section title
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Close Recall',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Close Recall Button
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                      onPressed: (_isUpdating || !_isSection3Completed() || _isRecallCompleted())
                          ? null
                          : () {
                              _updateStatus('Completed');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B5F6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _recall.recallResolutionStatus == 'Completed'
                                ? const Icon(
                                    Icons.check,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Close Recall',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isUpdating) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Register Note Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Register',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              ' - registering on a website to confirm your item is under recall and possibly your contact information.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'NOTE:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              ' Once you receive the new product, repair kit, or refund, your recall case is resolved.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // USDA Recall/Alert Link Button
            if (_recall.usdaRecallId.isNotEmpty && _recall.recallUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _openWebsite(_recall.recallUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7043),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'USDA Recall/Alert Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
