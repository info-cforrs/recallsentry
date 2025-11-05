import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../services/api_service.dart';

class UsdaReturnItemAccordion extends StatefulWidget {
  final RecallData recall;
  final Future<void> Function() onStatusUpdated;
  final bool isLocked;
  final bool isDisabled;
  final bool isExpanded;
  final Function(bool) onLockToggle;
  final Function(bool) onExpandToggle;

  const UsdaReturnItemAccordion({
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
  State<UsdaReturnItemAccordion> createState() =>
      _UsdaReturnItemAccordionState();
}

class _UsdaReturnItemAccordionState extends State<UsdaReturnItemAccordion> {
  bool _isUpdating = false;
  String? _lastSelectedStep1; // Track which step 1 option was selected (1A or 1B)

  @override
  void initState() {
    super.initState();
    // Initialize based on current status
    final status = widget.recall.recallResolutionStatus;
    if (status == 'Return 1A: Brought to local Retailer' || status == 'Return 2: Received Refund') {
      _lastSelectedStep1 = 'Return 1A: Brought to local Retailer';
    } else if (status == 'Return 1B: Item Shipped Back') {
      _lastSelectedStep1 = 'Return 1B: Item Shipped Back';
    }
  }

  // Check individual step status
  bool _isStepCompleted(String stepStatus) {
    final status = widget.recall.recallResolutionStatus;

    // If recall is completed and this accordion was locked, show completion based on last known state
    if (status == 'Completed' && widget.isLocked) {
      // Show step 2 (Receive Refund) as completed
      if (stepStatus == 'Return 2: Received Refund') {
        return true;
      }
      // Show the last selected step 1 option as completed
      if (stepStatus == 'Return 1A: Brought to local Retailer' ||
          stepStatus == 'Return 1B: Item Shipped Back') {
        return stepStatus == _lastSelectedStep1;
      }
    }

    // If we're at step 2, only show the last selected step 1 button as completed
    if (status == 'Return 2: Received Refund') {
      if (stepStatus == 'Return 1A: Brought to local Retailer' ||
          stepStatus == 'Return 1B: Item Shipped Back') {
        return stepStatus == _lastSelectedStep1;
      }
    }

    return status == stepStatus;
  }

  // Check if a step should be enabled (previous step completed)
  bool _isStepEnabled(int stepNumber) {
    final status = widget.recall.recallResolutionStatus;
    if (stepNumber == 1) {
      return true; // First step always enabled
    } else if (stepNumber == 2) {
      // Step 2 enabled if step 1A or 1B is completed
      return status == 'Return 1A: Brought to local Retailer' ||
          status == 'Return 1B: Item Shipped Back' ||
          status == 'Return 2: Received Refund';
    }
    return false;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
      // Track which step 1 button was selected
      if (newStatus == 'Return 1A: Brought to local Retailer' ||
          newStatus == 'Return 1B: Item Shipped Back') {
        _lastSelectedStep1 = newStatus;
      }
    });

    try {
      await ApiService().updateRecallStatus(widget.recall, newStatus);
      await widget.onStatusUpdated();
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
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
    // Clear all return-related statuses by setting back to previous step
    final status = widget.recall.recallResolutionStatus;
    if (status.startsWith('Return')) {
      setState(() {
        _isUpdating = true;
        _lastSelectedStep1 = null; // Clear the tracked selection
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
                      'Return Item',
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
              child: Column(
                children: [
                  // Row with two OR options in a white grouping box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Step 1A Button - Bring Item
                        Expanded(
                          child: _buildStepButton(
                            label: 'Bring Item to local Retailer',
                            status: 'Return 1A: Brought to local Retailer',
                            isCompleted: _isStepCompleted(
                                'Return 1A: Brought to local Retailer'),
                            isEnabled: _isStepEnabled(1) && !widget.isDisabled,
                            isToggleable: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Step 1B Button - Ship Item
                        Expanded(
                          child: _buildStepButton(
                            label: 'Ship Item Back',
                            status: 'Return 1B: Item Shipped Back',
                            isCompleted:
                                _isStepCompleted('Return 1B: Item Shipped Back'),
                            isEnabled: _isStepEnabled(1) && !widget.isDisabled,
                            isToggleable: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Arrow down - black color
                  const Icon(
                    Icons.arrow_downward,
                    color: Colors.black,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  // Step 2 Button - Receive Refund (centered at 50% width)
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: _buildStepButton(
                        label: 'Receive Refund',
                        status: 'Return 2: Received Refund',
                        isCompleted: _isStepCompleted('Return 2: Received Refund'),
                        isEnabled: _isStepEnabled(2) && !widget.isDisabled,
                      ),
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
    bool isToggleable = false,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled && !_isUpdating
            ? () {
                if (isToggleable && isCompleted) {
                  // If toggleable and already completed, clear it
                  _updateStatus('Mfr Contacted');
                } else {
                  _updateStatus(status);
                }
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
                  width: 20,
                  height: 20,
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
