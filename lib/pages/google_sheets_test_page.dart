import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';
import '../models/recall_data.dart';

class GoogleSheetsTestPage extends StatefulWidget {
  const GoogleSheetsTestPage({super.key});

  @override
  State<GoogleSheetsTestPage> createState() => _GoogleSheetsTestPageState();
}

class _GoogleSheetsTestPageState extends State<GoogleSheetsTestPage> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  final TextEditingController _spreadsheetIdController =
      TextEditingController();

  bool _isLoading = false;
  String _status = 'Ready to test';
  List<RecallData> _recalls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      appBar: AppBar(
        title: const Text('Google Sheets Test'),
        backgroundColor: const Color(0xFF2A4A5C),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              const Text(
                'Google Sheets Connection Test',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Enter your Google Spreadsheet ID:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),

              // Spreadsheet ID input
              TextField(
                controller: _spreadsheetIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste your spreadsheet ID here...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A4A5C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Test buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Test Connection'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addSampleData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Sample Data'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A4A5C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Status: $_status',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),

              // Results
              if (_recalls.isNotEmpty) ...[
                Text(
                  'Found ${_recalls.length} recalls:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _recalls.length,
                    itemBuilder: (context, index) {
                      final recall = _recalls[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: recall.agency == 'FDA'
                              ? const Color(
                                  0xFFFFF9C4,
                                ) // Yellow background for FDA
                              : const Color(0xFFE8F5E8), // Light green for USDA
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getRiskColor(recall.riskLevel),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      recall.productName,
                                      style: const TextStyle(
                                        color: Color(0xFF1D3547),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: recall.agency == 'FDA'
                                          ? const Color(
                                              0xFF1565C0,
                                            ).withValues(alpha: 0.2)
                                          : const Color(
                                              0xFF2E7D32,
                                            ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: recall.agency == 'FDA'
                                            ? const Color(0xFF1565C0)
                                            : const Color(0xFF2E7D32),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      recall.agency,
                                      style: TextStyle(
                                        color: recall.agency == 'FDA'
                                            ? const Color(0xFF1565C0)
                                            : const Color(0xFF2E7D32),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recall.description,
                                style: const TextStyle(
                                  color: Color(0xFF1D3547),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    recall.brandName,
                                    style: const TextStyle(
                                      color: Color(0xFF1D3547),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${recall.dateIssued.month}/${recall.dateIssued.day}/${recall.dateIssued.year}',
                                    style: const TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_spreadsheetIdController.text.trim().isEmpty) {
      setState(() {
        _status = 'Please enter a spreadsheet ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Connecting to Google Sheets...';
    });

    try {
      await _sheetsService.init(_spreadsheetIdController.text.trim());
      final recalls = await _sheetsService.fetchRecalls();

      setState(() {
        _recalls = recalls;
        _status = 'Connected successfully! Found ${recalls.length} recalls.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addSampleData() async {
    if (!_sheetsService.isInitialized) {
      try {
        final now = DateTime.now();
        final id = 'TEST- 2${now.millisecondsSinceEpoch}';
        final sampleRecall = RecallData(
          usdaRecallId: id,
          fdaRecallId: '',
          fieldRecallNumber: 'FRN-001',
          expDate: '',
          batchLotCode: '',
          upc: '',
          productIdentification: '',
          recallPhaReason: '',
          recallReason: '',
          sellByDate: '',
          sku: '',
          adverseReactions: '',
          adverseReactionDetails: '',
          id: id,
          productName: 'Sample Ground Beef Products',
          brandName: 'Test Foods Inc.',
          riskLevel: 'HIGH',
          dateIssued: now,
          agency: 'USDA',
          description:
              'Sample recall for testing purposes - possible Salmonella contamination',
          category: 'Food & Beverage',
          recallClassification: '',
          imageUrl: '',
          imageUrl2: '',
          imageUrl3: '',
          imageUrl4: '',
          imageUrl5: '',
          stateCount: 0,
          negativeOutcomes: '',
          packagingDesc: '',
          remedyReturn: '',
          remedyRepair: '',
          remedyReplace: '',
          remedyDispose: '',
          remedyNA: '',
          productQty: '',
          soldBy: '',
          productionDateStart: null,
          productionDateEnd: null,
          bestUsedByDate: '',
          recallReasonShort: '',
          pressReleaseLink: '',
          productTypeDetail: '',
          productSizeWeight: '',
          howFound: '',
          distributionPattern: '',
          recallingFdaFirm: '',
          firmContactName: '',
          firmContactPhone: '',
          firmContactBusinessHoursDays: '',
          firmContactEmail: '',
          firmContactWebSite: '',
          firmWebSiteInfo: '',
          recommendationsActions: '',
          remedy: '',
          productDistribution: '',
          establishmentManufacturer: '',
          establishmentManufacturerContactName: '',
          establishmentManufacturerContactPhone: '',
          establishmentManufacturerContactBusinessHoursDays: '',
          establishmentManufacturerContactEmail: '',
          establishmentManufacturerWebsite: '',
          establishmentManufacturerWebsiteInfo: '',
          retailer1: '',
          retailer1SaleDateStart: '',
          retailer1SaleDateEnd: '',
          retailer1ContactName: '',
          retailer1ContactPhone: '',
          retailer1ContactBusinessHoursDays: '',
          retailer1ContactEmail: '',
          retailer1ContactWebSite: '',
          retailer1WebSiteInfo: '',
          estItemValue: '',
          recallUrl: '',
          usdaToReportAProblem: '',
          usdaFoodSafetyQuestionsPhone: '',
          usdaFoodSafetyQuestionsEmail: '',
        );

        await _sheetsService.addRecall(sampleRecall);

        // Refresh the data
        final recalls = await _sheetsService.fetchRecalls();

        setState(() {
          _recalls = recalls;
          _status = 'Sample data added successfully!';
          _isLoading = false;
        });
      } catch (err) {
        setState(() {
          _status = 'Error adding sample data: $err';
          _isLoading = false;
        });
      }
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.yellow.shade700;
    }
  }
}
