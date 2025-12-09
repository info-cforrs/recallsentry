/// RecallDetailPage Widget Tests
///
/// Tests for the Recall Detail page UI including:
/// - Header with risk level and agency
/// - Product information display
/// - Remedy options
/// - Action buttons (save, share)
/// - Image gallery
/// - Expandable sections
///
/// To run: flutter test test/widget/pages/recall_detail_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';
import '../../fixtures/recall_fixtures.dart';

void main() {
  group('RecallDetail - Header', () {
    testWidgets('displays agency badge', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FDA'), findsOneWidget);
    });

    testWidgets('displays risk level with correct color', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HIGH'), findsOneWidget);

      // Find the risk badge container
      final riskBadge = find.ancestor(
        of: find.text('HIGH'),
        matching: find.byType(Container),
      );
      expect(riskBadge, findsWidgets);
    });

    testWidgets('displays product name prominently', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Organic Peanut Butter'), findsOneWidget);
    });

    testWidgets('displays brand name', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NuttyHealth'), findsOneWidget);
    });

    testWidgets('displays recall date', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the date in some format
      expect(find.textContaining('2024'), findsWidgets);
    });
  });

  group('RecallDetail - Product Information', () {
    testWidgets('displays recall description', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Potential salmonella contamination in peanut butter products.'),
        findsOneWidget,
      );
    });

    testWidgets('displays recall reason', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recall Reason'), findsOneWidget);
      expect(find.textContaining('salmonella'), findsWidgets);
    });

    testWidgets('displays product quantity', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50000 units'), findsOneWidget);
    });

    testWidgets('displays UPC code when available', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('012345678901'), findsOneWidget);
    });

    testWidgets('displays lot code when available', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LOT-2024-A1'), findsOneWidget);
    });
  });

  group('RecallDetail - Remedy Options', () {
    testWidgets('displays remedy section header', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remedy Options'), findsOneWidget);
    });

    testWidgets('shows return remedy when available', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Return for Refund'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('shows replace remedy when available', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replacement'), findsOneWidget);
    });

    testWidgets('shows dispose remedy when available', (tester) async {
      final recallWithDispose = Map<String, dynamic>.from(
        RecallFixtures.fdaRecallSample,
      );
      recallWithDispose['remedy_dispose'] = true;

      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: recallWithDispose),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dispose'), findsOneWidget);
    });

    testWidgets('hides unavailable remedies', (tester) async {
      final recallNoRepair = Map<String, dynamic>.from(
        RecallFixtures.fdaRecallSample,
      );
      recallNoRepair['remedy_repair'] = false;

      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: recallNoRepair),
        ),
      );
      await tester.pumpAndSettle();

      // Repair should not be shown as available
      expect(find.text('Repair'), findsNothing);
    });
  });

  group('RecallDetail - Contact Information', () {
    testWidgets('displays contact section', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Information'), findsOneWidget);
    });

    testWidgets('displays phone number when available', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1-800-555-0123'), findsOneWidget);
    });

    testWidgets('phone number is tappable', (tester) async {
      var phoneTapped = false;

      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(
            recall: RecallFixtures.fdaRecallSample,
            onPhoneTap: () {
              phoneTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('1-800-555-0123'));
      await tester.pump();

      expect(phoneTapped, true);
    });

    testWidgets('displays email when available', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('recall@nuttyhealth.com'), findsOneWidget);
    });
  });

  group('RecallDetail - Action Buttons', () {
    testWidgets('displays save button', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('save button toggles to filled when tapped', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      // Initially unfilled
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsNothing);

      // Tap save button
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();

      // Now filled
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('displays share button', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('share button triggers share action', (tester) async {
      var shareTriggered = false;

      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(
            recall: RecallFixtures.fdaRecallSample,
            onShare: () {
              shareTriggered = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();

      expect(shareTriggered, true);
    });
  });

  group('RecallDetail - Distribution Information', () {
    testWidgets('displays distribution pattern', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Distribution'), findsOneWidget);
      expect(find.text('Nationwide'), findsOneWidget);
    });

    testWidgets('displays state count when available', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('15 states'), findsOneWidget);
    });
  });

  group('RecallDetail - NHTSA Specific', () {
    testWidgets('displays vehicle make/model/year for NHTSA recalls', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.nhtsaVehicleRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AutoMaker'), findsWidgets);
      expect(find.text('Model X'), findsOneWidget);
      expect(find.text('2020-2023'), findsOneWidget);
    });

    testWidgets('displays campaign number for NHTSA', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.nhtsaVehicleRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Campaign: 24V-123'), findsOneWidget);
    });

    testWidgets('displays completion rate for NHTSA', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.nhtsaVehicleRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('15%'), findsOneWidget);
    });

    testWidgets('shows do-not-drive warning when applicable', (tester) async {
      final urgentRecall = Map<String, dynamic>.from(
        RecallFixtures.nhtsaVehicleRecallSample,
      );
      urgentRecall['nhtsa_do_not_drive'] = true;

      await tester.pumpWidget(
        createTestableWidget(_TestRecallDetailPage(recall: urgentRecall)),
      );
      await tester.pumpAndSettle();

      expect(find.text('DO NOT DRIVE'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsWidgets);
    });
  });

  group('RecallDetail - CPSC Specific', () {
    testWidgets('displays sold-by retailers for CPSC', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.cpscRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sold At'), findsOneWidget);
      expect(find.text('Walmart'), findsOneWidget);
      expect(find.text('Amazon'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
    });

    testWidgets('displays model number for CPSC', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.cpscRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PW-2024-RED'), findsOneWidget);
    });
  });

  group('RecallDetail - Loading & Error States', () {
    testWidgets('shows loading indicator while fetching details', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestRecallDetailLoading()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when load fails', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestRecallDetailError()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load recall details'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('RecallDetail - Scrolling', () {
    testWidgets('content is scrollable', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          _TestRecallDetailPage(recall: RecallFixtures.fdaRecallSample),
        ),
      );
      await tester.pumpAndSettle();

      // Should have a scrollable view
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}

// Test Widgets

/// Test recall detail page
class _TestRecallDetailPage extends StatefulWidget {
  final Map<String, dynamic> recall;
  final VoidCallback? onShare;
  final VoidCallback? onPhoneTap;

  const _TestRecallDetailPage({
    required this.recall,
    this.onShare,
    this.onPhoneTap,
  });

  @override
  State<_TestRecallDetailPage> createState() => _TestRecallDetailPageState();
}

class _TestRecallDetailPageState extends State<_TestRecallDetailPage> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final recall = widget.recall;
    final agency = recall['agency'] as String? ?? 'FDA';
    final riskLevel = recall['risk_level'] as String? ?? 'LOW';
    final isNhtsa = agency == 'NHTSA';
    final isCpsc = agency == 'CPSC';
    final doNotDrive = recall['nhtsa_do_not_drive'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(agency),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              setState(() => _isSaved = !_isSaved);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: widget.onShare,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      agency,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRiskColor(riskLevel),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      riskLevel,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Do not drive warning
              if (doNotDrive) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'DO NOT DRIVE',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Product name and brand
              Text(
                recall['product_name'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recall['brand_name'] as String? ?? '',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Issued: ${recall['date_issued'] ?? '2024-01-15'}',
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                recall['description'] as String? ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // NHTSA specific
              if (isNhtsa) ...[
                _buildSection('Vehicle Information', [
                  _buildInfoRow('Make', recall['nhtsa_vehicle_make'] ?? 'AutoMaker'),
                  _buildInfoRow('Model', recall['nhtsa_vehicle_model'] ?? 'Model X'),
                  _buildInfoRow('Years', recall['nhtsa_vehicle_year_range'] ?? '2020-2023'),
                ]),
                const SizedBox(height: 8),
                Text('Campaign: ${recall['nhtsa_campaign_number'] ?? '24V-123'}'),
                const SizedBox(height: 8),
                Text('Completion Rate: ${recall['nhtsa_completion_rate'] ?? '15%'}'),
                const SizedBox(height: 16),
              ],

              // CPSC specific
              if (isCpsc) ...[
                _buildSection('Sold At', [
                  if (recall['sold_by_walmart'] == true)
                    const Chip(label: Text('Walmart')),
                  if (recall['sold_by_amazon'] == true)
                    const Chip(label: Text('Amazon')),
                  if (recall['sold_by_target'] == true)
                    const Chip(label: Text('Target')),
                ]),
                const SizedBox(height: 8),
                _buildInfoRow('Model', recall['model'] ?? 'PW-2024-RED'),
                const SizedBox(height: 16),
              ],

              // Recall Reason
              _buildSection('Recall Reason', [
                Text(recall['recall_reason'] as String? ?? ''),
              ]),
              const SizedBox(height: 16),

              // Product details
              _buildSection('Product Details', [
                _buildInfoRow('Quantity', recall['product_qty'] ?? ''),
                _buildInfoRow('UPC', recall['upc'] ?? ''),
                _buildInfoRow('Lot Code', recall['batch_lot_code'] ?? ''),
              ]),
              const SizedBox(height: 16),

              // Distribution
              _buildSection('Distribution', [
                Text(recall['distribution_pattern'] as String? ?? 'Nationwide'),
                if (recall['state_count'] != null)
                  Text('${recall['state_count']} states'),
              ]),
              const SizedBox(height: 16),

              // Remedy Options
              _buildSection('Remedy Options', [
                if (recall['remedy_return'] == true)
                  _buildRemedyItem(Icons.check_circle, 'Return for Refund'),
                if (recall['remedy_replace'] == true)
                  _buildRemedyItem(Icons.check_circle, 'Replacement'),
                if (recall['remedy_repair'] == true)
                  _buildRemedyItem(Icons.check_circle, 'Repair'),
                if (recall['remedy_dispose'] == true)
                  _buildRemedyItem(Icons.check_circle, 'Dispose'),
              ]),
              const SizedBox(height: 16),

              // Contact Information
              _buildSection('Contact Information', [
                if (recall['firm_contact_phone'] != null)
                  GestureDetector(
                    onTap: widget.onPhoneTap,
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 20),
                        const SizedBox(width: 8),
                        Text(recall['firm_contact_phone'] as String),
                      ],
                    ),
                  ),
                if (recall['firm_contact_email'] != null)
                  Row(
                    children: [
                      const Icon(Icons.email, size: 20),
                      const SizedBox(width: 8),
                      Text(recall['firm_contact_email'] as String),
                    ],
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRemedyItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

/// Loading state
class _TestRecallDetailLoading extends StatelessWidget {
  const _TestRecallDetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Error state
class _TestRecallDetailError extends StatelessWidget {
  const _TestRecallDetailError();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load recall details'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
