import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recall_match.dart';
import '../services/recallmatch_service.dart';
import '../constants/app_colors.dart';
import '../widgets/recall_match_card.dart';
import '../modals/match_confirm_modal.dart';

/// RecallMatch Alert Page
///
/// Displays all pending recall matches for the user.
/// Groups matches by recall for better organization.
class RecallMatchAlertPage extends ConsumerStatefulWidget {
  const RecallMatchAlertPage({super.key});

  @override
  ConsumerState<RecallMatchAlertPage> createState() => _RecallMatchAlertPageState();
}

class _RecallMatchAlertPageState extends ConsumerState<RecallMatchAlertPage> {
  final RecallMatchService _service = RecallMatchService();
  List<RecallMatchSummary> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matches = await _service.getRecallMatches(
        status: MatchStatus.pendingReview,
        includeExpired: false,
      );

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshMatches() async {
    await _loadMatches();
  }

  Future<void> _onMatchConfirmed(RecallMatchSummary match) async {
    // Show confirmation modal
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MatchConfirmModal(match: match),
    );

    // If confirmed or changed, refresh the list
    if (result == true && mounted) {
      await _refreshMatches();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match confirmed and enrolled in RMC!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _onMatchDismissed(RecallMatchSummary match) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Match'),
        content: const Text(
          'Are you sure this is not your item?\n\n'
          'This will mark the match as a false positive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('NOT MY ITEM'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Dismiss the match
      await _service.dismissMatch(
        match.id,
        DismissMatchRequest(
          reason: 'Not my item',
          reasonCode: 'WRONG_PRODUCT',
        ),
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Refresh list
        _refreshMatches();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match dismissed'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Refresh list to remove stale matches (match may already be dismissed)
        _refreshMatches();

        // Show error with helpful message
        final errorMessage = e.toString().contains('cannot be dismissed')
            ? 'This match has already been processed'
            : 'Failed to dismiss match: $e';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Group matches by recall ID
  Map<String, List<RecallMatchSummary>> _groupMatchesByRecall() {
    final grouped = <String, List<RecallMatchSummary>>{};

    for (final match in _matches) {
      if (!grouped.containsKey(match.recall.id)) {
        grouped[match.recall.id] = [];
      }
      grouped[match.recall.id]!.add(match);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('RecallMatch Alerts'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMatches,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load matches',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshMatches,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'No Pending Matches',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You have no pending recall matches at this time.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMatches,
      child: _buildMatchesList(),
    );
  }

  Widget _buildMatchesList() {
    final groupedMatches = _groupMatchesByRecall();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: groupedMatches.length,
      itemBuilder: (context, index) {
        final recallId = groupedMatches.keys.elementAt(index);
        final matches = groupedMatches[recallId]!;
        final isLastGroup = index == groupedMatches.length - 1;

        return _buildRecallGroup(recallId, matches, isLastGroup);
      },
    );
  }

  Widget _buildRecallGroup(String recallId, List<RecallMatchSummary> matches, bool isLastGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match cards (no header text)
        ...matches.asMap().entries.map((entry) {
          final index = entry.key;
          final match = entry.value;
          final isLastMatch = index == matches.length - 1;

          return RecallMatchCard(
            match: match,
            onConfirm: () => _onMatchConfirmed(match),
            onDismiss: () => _onMatchDismissed(match),
            showDivider: !isLastMatch, // Show divider between matches in same group
          );
        }),

        // Add divider between recall groups (but not after the last group)
        if (!isLastGroup) ...[
          const SizedBox(height: 24),
          Container(
            height: 3,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
        ] else ...[
          const SizedBox(height: 16),
        ],
      ],
    );
  }

}
