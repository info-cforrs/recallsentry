/// RMC (Recall Management Center) Status Constants
///
/// This file defines all valid status values for RMC enrollments
/// to ensure consistency across the application.
library;

class RmcStatus {
  // ===== PRE-WORKFLOW STATUSES =====
  // These statuses occur before the user selects a resolution branch

  /// Initial status when recall is enrolled but user hasn't started process
  static const String notStarted = 'Not Started';

  /// User has indicated they stopped using the recalled product
  static const String stoppedUsing = 'Stopped Using';

  /// User has contacted the manufacturer
  static const String mfrContacted = 'Mfr Contacted';

  // ===== PATH SELECTION STATUSES =====
  // These statuses occur when user selects a resolution branch

  /// User selected Return path
  static const String returnSelected = 'Return Selected';

  /// User selected Repair path
  static const String repairSelected = 'Repair Selected';

  /// User selected Replace path
  static const String replaceSelected = 'Replace Selected';

  /// User selected Dispose path
  static const String disposeSelected = 'Dispose Selected';

  // ===== RETURN BRANCH STATUSES =====

  /// User is in process of shipping items back
  static const String shippingItemsBack = 'Shipping Items Back';

  /// User has shipped item back to manufacturer
  static const String shippedItemBack = 'Shipped Item Back';

  /// User is bringing item to local retailer
  static const String bringingItemToRetailer = 'Bringing item to retailer';

  /// User chose to bring item to local retailer for return
  static const String return1A = 'Return 1A: Brought to local Retailer';

  /// User chose to ship item back to manufacturer
  static const String return1B = 'Return 1B: Item Shipped Back';

  /// User received refund for returned item
  static const String return2 = 'Return 2: Received Refund';

  // ===== REPAIR BRANCH STATUSES =====

  /// User is waiting for repair kit or parts
  static const String waitingForRepairKitOrParts = 'Waiting for repair kit or parts';

  /// User is bringing item to service center
  static const String bringingItemToServiceCenter = 'Bringing item to service center';

  /// User brought item to authorized service center
  static const String repair1A = 'Repair 1A: Brought to Service Center';

  /// Item was repaired by service center
  static const String repair1B = 'Repair 1B: Item Repaired by Service Center';

  /// User received repair kit or replacement parts
  static const String repair2A = 'Repair 2A: Received Repair Kit or Parts';

  /// User successfully repaired the item themselves
  static const String repair2B = 'Repair 2B: Item Repaired by User';

  // ===== REPLACE BRANCH STATUSES =====

  /// User is waiting for replacement item
  static const String waitingReplacementItem = 'Waiting replacement item';

  /// User is waiting for replacement parts
  static const String waitingReplacementParts = 'Waiting replacement parts';

  /// User received replacement parts
  static const String replace1A = 'Replace 1A: Received Parts';

  /// User received complete replacement item
  static const String replace2A = 'Replace 2A: Received Replacement Item';

  // ===== DISPOSE BRANCH STATUSES =====

  /// User is disposing of item themselves
  static const String disposingOfItem = 'Disposing of item';

  /// User is bringing item to local retailer for disposal
  static const String bringingItemToLocalRetailer = 'Bringing item to local retailer';

  /// User disposed of item at retailer
  static const String disposedOfItemAtRetailer = 'Disposed of item at retailer';

  /// User brought item to retailer for disposal
  static const String dispose1A = 'Dispose 1A: Brought to local Retailer';

  /// User received refund after bringing to retailer
  static const String dispose1B = 'Dispose 1B: Received Refund';

  /// User properly disposed of the item
  static const String dispose2A = 'Dispose 2A: Disposed of Item';

  // ===== COMPLETION STATUSES =====

  /// Recall process successfully completed
  static const String completed = 'Completed';

  /// Recall process closed (alternative to completed)
  static const String closed = 'Closed';

  // ===== INTERNAL/BACKEND STATUSES =====

  /// Internal status for recalls not yet enrolled in RMC
  static const String notActive = 'Not Active';

  // ===== STATUS LISTS =====

  /// All pre-workflow statuses (before branch selection)
  static const List<String> preWorkflowStatuses = [
    notStarted,
    stoppedUsing,
    mfrContacted,
  ];

  /// All Return branch statuses
  static const List<String> returnStatuses = [
    shippingItemsBack,
    shippedItemBack,
    bringingItemToRetailer,
    return1A,
    return1B,
    return2,
  ];

  /// All Repair branch statuses
  static const List<String> repairStatuses = [
    waitingForRepairKitOrParts,
    bringingItemToServiceCenter,
    repair1A,
    repair1B,
    repair2A,
    repair2B,
  ];

  /// All Replace branch statuses
  static const List<String> replaceStatuses = [
    waitingReplacementItem,
    waitingReplacementParts,
    replace1A,
    replace2A,
  ];

  /// All Dispose branch statuses
  static const List<String> disposeStatuses = [
    disposingOfItem,
    bringingItemToLocalRetailer,
    disposedOfItemAtRetailer,
    dispose1A,
    dispose1B,
    dispose2A,
  ];

  /// All completion statuses
  static const List<String> completionStatuses = [
    completed,
    closed,
  ];

  /// All valid status values
  static const List<String> allValidStatuses = [
    // Pre-workflow
    notStarted,
    stoppedUsing,
    mfrContacted,
    // Path selection
    returnSelected,
    repairSelected,
    replaceSelected,
    disposeSelected,
    // Return branch
    shippingItemsBack,
    shippedItemBack,
    bringingItemToRetailer,
    return1A,
    return1B,
    return2,
    // Repair branch
    waitingForRepairKitOrParts,
    bringingItemToServiceCenter,
    repair1A,
    repair1B,
    repair2A,
    repair2B,
    // Replace branch
    waitingReplacementItem,
    waitingReplacementParts,
    replace1A,
    replace2A,
    // Dispose branch
    disposingOfItem,
    bringingItemToLocalRetailer,
    disposedOfItemAtRetailer,
    dispose1A,
    dispose1B,
    dispose2A,
    // Completion
    completed,
    closed,
    // Internal
    notActive,
  ];

  // ===== HELPER METHODS =====

  /// Checks if a status value is valid
  static bool isValid(String status) {
    return allValidStatuses.contains(status);
  }

  /// Checks if a status is a pre-workflow status
  static bool isPreWorkflow(String status) {
    return preWorkflowStatuses.contains(status);
  }

  /// Checks if a status is a completion status
  static bool isCompletion(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == completed.toLowerCase() ||
           normalized == closed.toLowerCase();
  }

  /// Checks if a status should be shown in "In Progress" category
  static bool isInProgress(String status) {
    final normalized = status.trim().toLowerCase();

    // Exclude pre-workflow and completion statuses
    return !isPreWorkflow(status) &&
           !isCompletion(status) &&
           normalized != notActive.toLowerCase();
  }

  /// Gets the branch type from a status value
  static String? getBranchType(String status) {
    if (returnStatuses.contains(status)) return 'Return';
    if (repairStatuses.contains(status)) return 'Repair';
    if (replaceStatuses.contains(status)) return 'Replace';
    if (disposeStatuses.contains(status)) return 'Dispose';
    return null;
  }
}
