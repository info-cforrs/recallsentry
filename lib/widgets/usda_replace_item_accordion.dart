import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../services/api_service.dart';

class UsdaReplaceItemAccordion extends StatefulWidget {
  final RecallData recall;
  final Future<void> Function() onStatusUpdated;
  final bool isLocked;
  final bool isDisabled;
  final bool isExpanded;
  final Function(bool) onLockToggle;
  final Function(bool) onExpandToggle;

  const UsdaReplaceItemAccordion({
    super.key,
    required this.recall,
    required this.onStatusUpdated,
    required this.isLocked,
    required this.isDisabled,
    required this.isExpanded,
    required this.onLockToggle,
    required this.onExpandToggle,
  });

  @override
  State<UsdaReplaceItemAccordion> createState() =>
      _UsdaReplaceItemAccordionState();
}

class _UsdaReplaceItemAccordionState extends State<UsdaReplaceItemAccordion> {
  bool _isUpdating = false;
  String? _completedBeforeClose; // Track which step was completed before closing

  @override
  void initState() {
    super.initState();
    // Initialize based on current status
    final status = widget.recall.recallResolutionStatus;
    if (status == 'Replace 1A: Received Parts' || status == 'Replace 2A: Received Replacement Item') {
      _completedBeforeClose = status;
    }
  }

  @override
  void didUpdateWidget(UsdaReplaceItemAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Track the status before it becomes 'Completed'
    final status = widget.recall.recallResolutionStatus;
    if (status == 'Replace 1A: Received Parts' || status == 'Replace 2A: Received Replacement Item') {
      _completedBeforeClose = status;
    }
  }

  // Check individual step status
  bool _isStepCompleted(String stepStatus) {
    final status = widget.recall.recallResolutionStatus;
    print('DEBUG Replace: Checking if $stepStatus is completed. Current status: $status');

    // If recall is completed and this accordion was locked, show the step that was completed before closing
    if (status == 'Completed' && widget.isLocked && _completedBeforeClose != null) {
      return stepStatus == _completedBeforeClose;
    }

    return status == stepStatus;
  }

  // Check if a step should be enabled (previous step completed)
  bool _isStepEnabled(int stepNumber) {
    final status = widget.recall.recallResolutionStatus;
    if (stepNumber == 1) {
      return true; // First step always enabled
    } else if (stepNumber == 2) {
      // Step 2 enabled if step 1A is completed
      return status == 'Replace 1A: Received Parts' ||
          status == 'Replace 2A: Received Replacement Item';
    }
    return false;
  }

  Future<void> _updateStatus(String newStatus) async {
    print('DEBUG Replace: _updateStatus called with: $newStatus');
    setState(() {
      _isUpdating = true;
    });

    try {
      print('DEBUG Replace: Before API call');
      // The updateRecallStatus method returns the updated recall, but we still need to
      // refresh from parent to ensure all widgets get the updated data
      await ApiService().updateRecallStatus(widget.recall, newStatus);
      print('DEBUG Replace: After API call, before parent refresh');
      await widget.onStatusUpdated();
      print('DEBUG Replace: After parent refresh. Current status: ${widget.recall.recallResolutionStatus}');
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _clearAllStatuses() async {
    final status = widget.recall.recallResolutionStatus;
    if (status.startsWith('Replace')) {
      setState(() {
        _isUpdating = true;
      });
      try {
        await ApiService().updateRecallStatus(widget.recall, 'Mfr Contacted');
        await widget.onStatusUpdated();
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF5DADE2),
          borderRadius: BorderRadius.circular(12),
        ),
      child: Column(
        children: [
          // Accordion Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Checkbox on the left - clickable to lock/unlock
                GestureDetector(
                  onTap: widget.isDisabled
                      ? null
                      : () async {
                          if (widget.isLocked) {
                            // Unlocking - clear all statuses
                            await _clearAllStatuses();
                            widget.onLockToggle(false);
                          } else {
                            // Locking
                            widget.onLockToggle(true);
                          }
                        },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: widget.isLocked
                        ? const Icon(
                            Icons.check,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                const Expanded(
                  child: Text(
                    'Replace Item',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Expand/Collapse icon - clickable to expand/collapse
                GestureDetector(
                  onTap: widget.isDisabled
                      ? null
                      : () {
                          widget.onExpandToggle(!widget.isExpanded);
                        },
                  child: Icon(
                    widget.isExpanded ? Icons.remove : Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Accordion Body
          if (widget.isExpanded && !widget.isDisabled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF5DADE2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Replacement Parts
                  Expanded(
                    child: Column(
                      children: [
                        // Step 1A Button
                        _buildStepButton(
                          label: 'Receive Replacement Parts',
                          status: 'Replace 1A: Received Parts',
                          isCompleted: _isStepCompleted('Replace 1A: Received Parts'),
                          isEnabled: _isStepEnabled(1) && !widget.isDisabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Column - Replacement Item
                  Expanded(
                    child: Column(
                      children: [
                        // Step 2A Button
                        _buildStepButton(
                          label: 'Receive Replacement Item',
                          status: 'Replace 2A: Received Replacement Item',
                          isCompleted:
                              _isStepCompleted('Replace 2A: Received Replacement Item'),
                          isEnabled: _isStepEnabled(1) && !widget.isDisabled,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildStepButton({
    required String label,
    required String status,
    required bool isCompleted,
    required bool isEnabled,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled && !_isUpdating
            ? () {
                _updateStatus(status);
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF2C5F7F)
                : const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF2C5F7F)
                  : const Color(0xFFCCCCCC),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF4CAF50) : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        isCompleted ? const Color(0xFF4CAF50) : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Loading indicator
              if (_isUpdating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
