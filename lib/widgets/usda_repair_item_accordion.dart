import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../services/api_service.dart';

class UsdaRepairItemAccordion extends StatefulWidget {
  final RecallData recall;
  final Future<void> Function() onStatusUpdated;
  final bool isLocked;
  final bool isDisabled;
  final bool isExpanded;
  final Function(bool) onLockToggle;
  final Function(bool) onExpandToggle;

  const UsdaRepairItemAccordion({
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
  State<UsdaRepairItemAccordion> createState() =>
      _UsdaRepairItemAccordionState();
}

class _UsdaRepairItemAccordionState extends State<UsdaRepairItemAccordion> {
  bool _isUpdating = false;
  String? _completedPathBeforeClose; // Track which path was completed before closing (left or right)

  @override
  void initState() {
    super.initState();
    // Initialize based on current status
    final status = widget.recall.recallResolutionStatus;
    if (status.startsWith('Repair 1')) {
      _completedPathBeforeClose = 'left'; // Service Center path
    } else if (status.startsWith('Repair 2')) {
      _completedPathBeforeClose = 'right'; // DIY path
    }
  }

  @override
  void didUpdateWidget(UsdaRepairItemAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Track the path before it becomes 'Completed'
    final status = widget.recall.recallResolutionStatus;
    if (status.startsWith('Repair 1')) {
      _completedPathBeforeClose = 'left';
    } else if (status.startsWith('Repair 2')) {
      _completedPathBeforeClose = 'right';
    }
  }

  // Check individual step status
  bool _isStepCompleted(String stepStatus) {
    final status = widget.recall.recallResolutionStatus;

    // If recall is completed and this accordion was locked, show the path that was completed
    if (status == 'Completed' && widget.isLocked && _completedPathBeforeClose != null) {
      if (_completedPathBeforeClose == 'left') {
        // Service Center path - show both 1A and 1B as completed
        return stepStatus == 'Repair 1A: Brought to Service Center' ||
               stepStatus == 'Repair 1B: Item Repaired by Service Center';
      } else if (_completedPathBeforeClose == 'right') {
        // DIY path - show both 2A and 2B as completed
        return stepStatus == 'Repair 2A: Received Repair Kit or Parts' ||
               stepStatus == 'Repair 2B: Item Repaired by User';
      }
    }

    return status == stepStatus;
  }

  // Check if a step should be enabled based on current status
  bool _isStepEnabled(int stepNumber) {
    final status = widget.recall.recallResolutionStatus;

    // Initially, both step 1 (1A - Service Center) and step 3 (2A - DIY) are enabled
    if (stepNumber == 1) {
      // Step 1A is disabled if any right path (Repair 2) status is set
      return !status.startsWith('Repair 2');
    } else if (stepNumber == 2) {
      // Step 1B (Repaired by Service Center) enabled only if step 1A is completed
      return status == 'Repair 1A: Brought to Service Center' ||
          status == 'Repair 1B: Item Repaired by Service Center';
    } else if (stepNumber == 3) {
      // Step 2A (Receive Parts) is disabled if left path (1A or 1B) is chosen
      return !status.startsWith('Repair 1');
    } else if (stepNumber == 4) {
      // Step 2B (Repair with Parts) enabled only if step 2A is completed
      return status == 'Repair 2A: Received Repair Kit or Parts' ||
          status == 'Repair 2B: Item Repaired by User';
    }
    return false;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await ApiService().updateRecallStatus(widget.recall, newStatus);
      await widget.onStatusUpdated();
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

  Future<void> _clearAllStatuses() async {
    final status = widget.recall.recallResolutionStatus;
    if (status.startsWith('Repair')) {
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
                    'Repair Item',
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
                  // Left Column - Service Center Path with white grouping box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Step 1A Button
                          _buildStepButton(
                            label: 'Bring Item to local Service Center or Dealer',
                            status: 'Repair 1A: Brought to Service Center',
                            isCompleted: widget.recall.recallResolutionStatus.startsWith('Repair 1'),
                            isEnabled: _isStepEnabled(1) && !widget.isDisabled,
                            isToggleable: true,
                          ),
                          const SizedBox(height: 12),
                          // Arrow down - blue color
                          const Icon(
                            Icons.arrow_downward,
                            color: Color(0xFF5DADE2),
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          // Step 1B Button
                          _buildStepButton(
                            label: 'Item repaired by Service Center/Dealer',
                            status: 'Repair 1B: Item Repaired by Service Center',
                            isCompleted:
                                _isStepCompleted('Repair 1B: Item Repaired by Service Center'),
                            isEnabled: _isStepEnabled(2) && !widget.isDisabled,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Column - DIY Repair Path with white grouping box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Step 2A Button
                          _buildStepButton(
                            label: 'Receive Repair Kit or Parts',
                            status: 'Repair 2A: Received Repair Kit or Parts',
                            isCompleted: widget.recall.recallResolutionStatus.startsWith('Repair 2'),
                            isEnabled: _isStepEnabled(3) && !widget.isDisabled,
                            isToggleable: true,
                          ),
                          const SizedBox(height: 12),
                          // Arrow down - blue color
                          const Icon(
                            Icons.arrow_downward,
                            color: Color(0xFF5DADE2),
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          // Step 2B Button
                          _buildStepButton(
                            label: 'Repair Item with provided Parts',
                            status: 'Repair 2B: Item Repaired by User',
                            isCompleted:
                                _isStepCompleted('Repair 2B: Item Repaired by User'),
                            isEnabled: _isStepEnabled(4) && !widget.isDisabled,
                          ),
                        ],
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
