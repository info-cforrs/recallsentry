import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recall_data.dart';
import '../widgets/small_fda_recall_card.dart';
import '../widgets/small_usda_recall_card.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_loading_indicator.dart';
import '../providers/data_providers.dart';

/// New Recalls Page - Shows recalls from today and yesterday
/// Migrated to Riverpod for real-time updates
class NewRecallsPage extends ConsumerWidget {
  const NewRecallsPage({super.key});

  /// Filter recalls to only show those from today or yesterday
  List<RecallData> _filterNewRecalls(List<RecallData> allRecalls) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final yesterdayMidnight = todayMidnight.subtract(const Duration(days: 1));

    debugPrint('📅 Date filter:');
    debugPrint('   Current time: $now');
    debugPrint('   Today midnight: $todayMidnight');
    debugPrint('   Yesterday midnight: $yesterdayMidnight');

    final newRecalls = allRecalls.where((recall) {
      final dateIssued = recall.dateIssued;
      final isMatch = dateIssued.isAtSameMomentAs(yesterdayMidnight) ||
                      dateIssued.isAfter(yesterdayMidnight);

      if (isMatch) {
        debugPrint('   ✅ MATCH: ${recall.id} - ${recall.dateIssued}');
      }

      // Include recalls from today or yesterday (on or after yesterday's midnight)
      return isMatch;
    }).toList();

    debugPrint('📊 Filtered to ${newRecalls.length} new recalls');

    // Sort by date issued (newest first)
    newRecalls.sort((a, b) => b.dateIssued.compareTo(a.dateIssued));

    return newRecalls;
  }

  Widget _buildEmptyState({String? errorMessage, VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            errorMessage != null
                ? Icons.error_outline
                : Icons.info_outline,
            size: 80,
            color: errorMessage != null ? Colors.red : Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage != null
                ? 'Error Loading Recalls'
                : 'No New Recalls',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'No new recalls today or yesterday',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecallsList(List<RecallData> newRecalls) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner showing count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF64B5F6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${newRecalls.length} recall${newRecalls.length == 1 ? '' : 's'} today and yesterday',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recalls list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: newRecalls.length,
            itemBuilder: (context, index) {
              final recall = newRecalls[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: recall.id.startsWith('FDA')
                    ? SmallFdaRecallCard(recall: recall)
                    : SmallUsdaRecallCard(recall: recall),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the filteredRecallsProvider for all recalls
    final recallsAsync = ref.watch(filteredRecallsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button and Centered App Icon + Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  // Back button on the left
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CustomBackButton(),
                  ),
                  // Centered App Icon and Title
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Image.asset(
                            'assets/images/shield_logo4.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'New Recalls',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Atlanta',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Content Area - Use AsyncValue.when() for state handling
            Expanded(
              child: recallsAsync.when(
                data: (allRecalls) {
                  debugPrint('📊 NewRecallsPage: Fetched ${allRecalls.length} total recalls');

                  // Filter recalls to today and yesterday
                  final newRecalls = _filterNewRecalls(allRecalls);

                  if (newRecalls.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      // Invalidate provider to force refresh
                      ref.invalidate(filteredRecallsProvider);
                    },
                    color: const Color(0xFF64B5F6),
                    backgroundColor: const Color(0xFF2C3E50),
                    child: _buildRecallsList(newRecalls),
                  );
                },
                loading: () => const CustomLoadingIndicator(
                  size: LoadingIndicatorSize.medium,
                ),
                error: (error, stackTrace) {
                  final errorMessage = 'Error loading new recalls: $error';
                  return _buildEmptyState(
                    errorMessage: errorMessage,
                    onRetry: () {
                      // Invalidate provider to retry
                      ref.invalidate(filteredRecallsProvider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
