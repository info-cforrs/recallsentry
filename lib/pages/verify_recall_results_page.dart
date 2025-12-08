import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/recallmatch_service.dart';
import '../services/api_service.dart';
import '../models/user_item.dart';
import '../models/recall_match.dart';
import 'rmc_details_page.dart';
import 'main_navigation.dart';

/// Verify Recall Results Page
///
/// Shows results after adding an item to inventory and checking for recalls.
/// - If recall match found: Shows match details with option to start RMC
/// - If no match found: Shows "Item is safe" message
class VerifyRecallResultsPage extends StatefulWidget {
  final UserItem createdItem;
  final String itemType;

  const VerifyRecallResultsPage({
    super.key,
    required this.createdItem,
    required this.itemType,
  });

  @override
  State<VerifyRecallResultsPage> createState() => _VerifyRecallResultsPageState();
}

class _VerifyRecallResultsPageState extends State<VerifyRecallResultsPage> {
  final RecallMatchService _recallMatchService = RecallMatchService();
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isStartingRmc = false;
  RecallMatchSummary? _recallMatch;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkForRecalls();
  }

  Future<void> _checkForRecalls() async {
    try {
      // Try to trigger rematch to find any recalls for this item
      // This may fail with 404 if the endpoint doesn't exist or
      // if matching happens automatically during item creation
      try {
        await _recallMatchService.rematchUserItem(widget.createdItem.id);
      } catch (e) {
        // Ignore rematch errors - matching may have happened automatically
        debugPrint('Rematch call failed (this is OK): $e');
      }

      // Fetch the item's recall match (if any)
      final match = await _recallMatchService.getMatchForItem(widget.createdItem.id);

      if (mounted) {
        setState(() {
          _recallMatch = match;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking for recalls: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startRmcProcess() async {
    if (_recallMatch == null) return;

    setState(() {
      _isStartingRmc = true;
    });

    try {
      // Enroll in RMC
      final enrollment = await _apiService.enrollRecallInRmc(
        recallId: _recallMatch!.recall.databaseId!,
        rmcStatus: 'Not Started',
      );

      if (!mounted) return;

      // Navigate to RMC Details page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RmcDetailsPage(
            recall: _recallMatch!.recall,
            enrollment: enrollment,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting recall process: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isStartingRmc = false;
      });
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainNavigation(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _goHome,
        ),
        title: const Text(
          'Recall Check Results',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _recallMatch != null
                    ? _buildRecallFoundState()
                    : _buildNoRecallState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            'Checking for recalls...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re scanning our database for any matching recalls',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _goHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecallState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Success icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 80,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Great News!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your item is not under recall',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We checked our database and found no active recalls matching your item. Your item has been added to your inventory.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Item info card
          _buildItemInfoCard(),
          const SizedBox(height: 24),
          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.accentBlue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We\'ll continue monitoring and notify you if a recall is issued for this item.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Done button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _goHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecallFoundState() {
    final recall = _recallMatch!.recall;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Warning icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF9800),
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recall Found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your item may be affected by a recall',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          // Recall info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF9800).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agency badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    recall.agency,
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  recall.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (recall.brandName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    recall.brandName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Recall reason
                if (recall.recallReason.isNotEmpty || recall.description.isNotEmpty) ...[
                  const Text(
                    'REASON',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.recallReason.isNotEmpty ? recall.recallReason : recall.description,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Date issued
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Issued: ${_formatDate(recall.dateIssued)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Item info card
          _buildItemInfoCard(),
          const SizedBox(height: 32),
          // Start RMC button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isStartingRmc ? null : _startRmcProcess,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isStartingRmc
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Starting...',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : const Text(
                      'Start Recall Resolution',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Skip button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: _goHome,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text(
                'I\'ll do this later',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR ITEM',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.createdItem.displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.createdItem.modelNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Model: ${widget.createdItem.modelNumber}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
