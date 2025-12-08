import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recall_match.dart';
import '../services/recallmatch_service.dart';

/// Match Confirmation Modal v2.0
///
/// Modal dialog for confirming a RecallMatch with dynamic identifier fields.
///
/// Features:
/// - Dynamically shows only fields that the recall has data for
/// - "Rerun RecallMatch" button to validate user-provided identifiers
/// - Disqualification display when identifiers don't match
/// - Three actions: Cancel, Rerun RecallMatch, Start Recall
class MatchConfirmModal extends StatefulWidget {
  final RecallMatchSummary match;

  const MatchConfirmModal({
    super.key,
    required this.match,
  });

  @override
  State<MatchConfirmModal> createState() => _MatchConfirmModalState();
}

class _MatchConfirmModalState extends State<MatchConfirmModal> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for identifier fields
  final _upcController = TextEditingController();
  final _modelNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _batchLotCodeController = TextEditingController();
  DateTime? _itemDate;

  // State
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isRevalidating = false;
  bool _isDisqualified = false;
  String? _disqualifiedMessage;
  double? _updatedScore;
  String? _updatedConfidence;
  RecallAvailableFields? _availableFields;

  final RecallMatchService _service = RecallMatchService();

  @override
  void initState() {
    super.initState();
    _loadAvailableFields();
  }

  @override
  void dispose() {
    _upcController.dispose();
    _modelNumberController.dispose();
    _serialNumberController.dispose();
    _batchLotCodeController.dispose();
    super.dispose();
  }

  /// Load available fields from the recall data
  Future<void> _loadAvailableFields() async {
    try {
      // First try to get from the recall data directly
      final recall = widget.match.recall;
      _availableFields = RecallAvailableFields.fromRecallData(recall);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Fallback: try API endpoint
      try {
        final fields = await _service.getRecallAvailableFields(widget.match.id);
        setState(() {
          _availableFields = fields;
          _isLoading = false;
        });
      } catch (apiError) {
        // If both fail, show all fields as fallback
        setState(() {
          _availableFields = RecallAvailableFields(
            hasUpc: true,
            hasModelNumber: widget.match.recall.agency == 'CPSC',
            hasSerialNumber: widget.match.recall.agency == 'CPSC',
            hasBatchLotCode: true,
            hasDate: true,
          );
          _isLoading = false;
        });
      }
    }
  }

  /// Check if user has entered any data
  bool get _hasUserData {
    return _upcController.text.trim().isNotEmpty ||
           _modelNumberController.text.trim().isNotEmpty ||
           _serialNumberController.text.trim().isNotEmpty ||
           _batchLotCodeController.text.trim().isNotEmpty ||
           _itemDate != null;
  }

  /// Select date for item
  Future<void> _selectItemDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Select Date from Product',
    );

    if (picked != null) {
      setState(() {
        _itemDate = picked;
        // Reset disqualification when user changes data
        _isDisqualified = false;
        _disqualifiedMessage = null;
      });
    }
  }

  /// Handle text field changes - reset disqualification state and trigger rebuild
  void _onFieldChanged() {
    setState(() {
      if (_isDisqualified) {
        _isDisqualified = false;
        _disqualifiedMessage = null;
        _updatedScore = null;
        _updatedConfidence = null;
      }
    });
  }

  /// Revalidate match with user-provided fields
  Future<void> _revalidateMatch() async {
    if (!_hasUserData) return;

    setState(() {
      _isRevalidating = true;
      _isDisqualified = false;
      _disqualifiedMessage = null;
    });

    try {
      final request = RevalidateMatchRequest(
        upc: _upcController.text.trim().isEmpty ? null : _upcController.text.trim(),
        modelNumber: _modelNumberController.text.trim().isEmpty ? null : _modelNumberController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
        batchLotCode: _batchLotCodeController.text.trim().isEmpty ? null : _batchLotCodeController.text.trim(),
        itemDate: _itemDate,
      );

      final response = await _service.revalidateMatch(widget.match.id, request);

      if (!mounted) return;

      setState(() {
        _isRevalidating = false;

        if (response.disqualified) {
          _isDisqualified = true;
          _disqualifiedMessage = response.disqualifiedMessage ??
              'Based on the information provided your item is not included in this recall.';
        } else {
          _updatedScore = response.matchScore;
          _updatedConfidence = response.matchConfidence;
        }
      });

      if (!response.disqualified) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Match validated! Score: ${response.matchScore.round()}%'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRevalidating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to validate: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Submit and start recall process
  Future<void> _submitForm() async {
    if (_isDisqualified) {
      // Don't allow submission if disqualified
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot start recall - item does not match this recall.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = ConfirmMatchRequest(
        lotNumber: _batchLotCodeController.text.trim().isEmpty
            ? null
            : _batchLotCodeController.text.trim(),
        purchaseDate: null, // Not collecting purchase date in v2
        purchaseLocation: null, // Not collecting purchase location in v2
      );

      await _service.confirmMatch(widget.match.id, request);

      if (!mounted) return;

      // Close modal with success
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final errorString = e.toString();
      final isAlreadyProcessed = errorString.contains('cannot be confirmed') ||
                                  errorString.contains('cannot be dismissed');

      if (isAlreadyProcessed) {
        Navigator.pop(context, true);
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm match: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    _buildInfoText(),
                    const SizedBox(height: 16),
                    _buildMatchScoreDisplay(),
                    const SizedBox(height: 16),
                    if (!_isDisqualified) _buildIdentifierFields(),
                    const SizedBox(height: 16),
                    if (!_isDisqualified && _availableFields?.hasAnyFields == true)
                      _buildInfoBox(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _isDisqualified ? Icons.cancel : Icons.check_circle,
          color: _isDisqualified ? Colors.red : Colors.green,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _isDisqualified ? 'Not a Match' : 'Confirm Match',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isDisqualified ? Colors.red : null,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: (_isSubmitting || _isRevalidating)
              ? null
              : () => Navigator.pop(context, _isDisqualified),
        ),
      ],
    );
  }

  Widget _buildInfoText() {
    if (_isDisqualified) {
      return Text(
        _disqualifiedMessage ?? 'This item does not match the recall.',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      );
    }

    final hasFields = _availableFields?.hasAnyFields ?? false;

    if (hasFields) {
      return Text(
        'You can provide additional details from your item to verify this match or just click Start Recall.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    } else {
      return Text(
        'Ready to start the recall process for this item.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
  }

  Widget _buildMatchScoreDisplay() {
    final score = _updatedScore ?? widget.match.matchScore;
    final confidence = _updatedConfidence ?? widget.match.getConfidenceText();

    Color scoreColor;
    if (score >= 90) {
      scoreColor = Colors.green;
    } else if (score >= 70) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor, width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Match Score: ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${score.round()}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scoreColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                confidence,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentifierFields() {
    if (_availableFields == null || !_availableFields!.hasAnyFields) {
      return const SizedBox.shrink();
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UPC Field
          if (_availableFields!.hasUpc) ...[
            TextFormField(
              controller: _upcController,
              decoration: const InputDecoration(
                labelText: 'UPC Code',
                hintText: 'Enter UPC from product packaging',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              enabled: !_isSubmitting && !_isRevalidating,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 16),
          ],

          // Model Number Field (CPSC only)
          if (_availableFields!.hasModelNumber) ...[
            TextFormField(
              controller: _modelNumberController,
              decoration: const InputDecoration(
                labelText: 'Model Number',
                hintText: 'Enter model number from product',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              enabled: !_isSubmitting && !_isRevalidating,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 16),
          ],

          // Serial Number Field (CPSC only)
          if (_availableFields!.hasSerialNumber) ...[
            TextFormField(
              controller: _serialNumberController,
              decoration: const InputDecoration(
                labelText: 'Serial Number',
                hintText: 'Enter serial number from product',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              enabled: !_isSubmitting && !_isRevalidating,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 16),
          ],

          // Batch/Lot Code Field
          if (_availableFields!.hasBatchLotCode) ...[
            TextFormField(
              controller: _batchLotCodeController,
              decoration: const InputDecoration(
                labelText: 'Batch/Lot Code',
                hintText: 'Enter batch or lot code from product',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              enabled: !_isSubmitting && !_isRevalidating,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => _onFieldChanged(),
            ),
            const SizedBox(height: 16),
          ],

          // Date Field
          if (_availableFields!.hasDate) ...[
            InkWell(
              onTap: (_isSubmitting || _isRevalidating) ? null : _selectItemDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date (Best By, Exp, Production, etc.)',
                  hintText: 'Select date from product',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: _itemDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: (_isSubmitting || _isRevalidating)
                              ? null
                              : () {
                                  setState(() {
                                    _itemDate = null;
                                    _onFieldChanged();
                                  });
                                },
                        )
                      : null,
                ),
                child: Text(
                  _itemDate != null
                      ? DateFormat('MMM dd, yyyy').format(_itemDate!)
                      : 'Tap to select date',
                  style: TextStyle(
                    color: _itemDate != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Adding identifier information helps verify this is the exact recalled product. If the identifiers don\'t match, this item will be removed from matches.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasFields = _availableFields?.hasAnyFields ?? false;

    return Column(
      children: [
        // Rerun RecallMatch button (only if fields available and user has entered data)
        if (hasFields && !_isDisqualified) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_isSubmitting || _isRevalidating || !_hasUserData)
                  ? null
                  : _revalidateMatch,
              icon: _isRevalidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isRevalidating ? 'Validating...' : 'Rerun RecallMatch'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Main action buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Cancel button
            TextButton(
              onPressed: (_isSubmitting || _isRevalidating)
                  ? null
                  : () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            const SizedBox(width: 12),

            // Start Recall button
            Flexible(
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isRevalidating || _isDisqualified)
                    ? null
                    : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDisqualified ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Start Recall',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
