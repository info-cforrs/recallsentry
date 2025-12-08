import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recall_data.dart';
import '../models/rmc_enrollment.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../widgets/small_fda_recall_card.dart';
import '../widgets/small_usda_recall_card.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';
import 'main_navigation.dart';
import 'rmc_status_page.dart';
import '../services/api_service.dart';
import '../constants/rmc_status.dart';
import 'package:rs_flutter/constants/app_colors.dart';

enum ResolutionBranch { returnPath, repair, replace, dispose, proof }

enum StepState { locked, active, done }

class RmcDetailsPage extends StatefulWidget {
  final RecallData recall;
  final RmcEnrollment? enrollment;

  const RmcDetailsPage({
    required this.recall,
    this.enrollment,
    super.key,
  });

  @override
  State<RmcDetailsPage> createState() => _RmcDetailsPageState();
}

class _RmcDetailsPageState extends State<RmcDetailsPage> with HideOnScrollMixin {
  // RMC Enrollment tracking
  RmcEnrollment? _enrollment;

  // Pre-step states
  bool stoppedUsing = false;
  String? contactMethod;
  ResolutionBranch? selectedBranch;

  // Branch-specific states
  String? branchChoice;

  // Proof branch specific states
  String? userPurchasedItemFrom;
  String? userPurchasedItemDate;
  String? userItemSN;
  String? userProofPic1Path;
  String? userProofPic2Path;
  final ImagePicker _imagePicker = ImagePicker();

  // Text controllers for proof branch
  final TextEditingController _purchaseFromController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();

  // Current step tracking
  int currentStepIndex = 0;
  final List<String> preStepTitles = ['Stop Using', 'Contact', 'Choose Path'];

  // Auto-save and state management
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  String? _lastSaveError;
  DateTime? _lastSavedAt;
  bool _hasUnsavedChanges = false;

  // Local storage keys for Proof step data persistence
  String get _proofStorageKey => 'proof_step_data_${widget.enrollment?.id ?? widget.recall.databaseId ?? 0}';

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    _enrollment = widget.enrollment;
    _initializeFromEnrollment();
    _loadProofStepDataFromStorage();
    _startAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _purchaseFromController.dispose();
    _purchaseDateController.dispose();
    _serialNumberController.dispose();
    disposeHideOnScroll();
    super.dispose();
  }

  void _initializeFromEnrollment() {
    // If we have an existing enrollment, restore its state
    if (_enrollment != null) {
      final status = _enrollment!.status;

      // Map backend status to workflow state (case-insensitive)
      final normalizedStatus = status.trim().toLowerCase();

      // Pre-workflow statuses
      if (normalizedStatus == RmcStatus.notActive.toLowerCase()) {
        // Not yet started, keep all defaults
        currentStepIndex = 0;
      } else if (normalizedStatus == RmcStatus.notStarted.toLowerCase()) {
        // User started but hasn't progressed
        currentStepIndex = 0;
      } else if (normalizedStatus == RmcStatus.stoppedUsing.toLowerCase()) {
        stoppedUsing = true;
        currentStepIndex = 1;
      } else if (normalizedStatus == RmcStatus.mfrContacted.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        currentStepIndex = 2;
      }
      // Path selection statuses
      else if (normalizedStatus == RmcStatus.returnSelected.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.returnPath;
        currentStepIndex = 3;
      } else if (normalizedStatus == RmcStatus.repairSelected.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.repair;
        currentStepIndex = 3;
      } else if (normalizedStatus == RmcStatus.replaceSelected.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.replace;
        currentStepIndex = 3;
      } else if (normalizedStatus == RmcStatus.disposeSelected.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.dispose;
        currentStepIndex = 3;
      }
      // Return branch statuses - new workflow
      else if (normalizedStatus == RmcStatus.shippingItemsBack.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.returnPath;
        branchChoice = 'ship';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.shippedItemBack.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.returnPath;
        branchChoice = 'ship';
        currentStepIndex = 5;
      } else if (normalizedStatus == RmcStatus.bringingItemToRetailer.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.returnPath;
        branchChoice = 'retailer';
        currentStepIndex = 4;
      }
      // Return branch statuses - legacy
      else if (normalizedStatus == RmcStatus.return1A.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.returnPath;
        branchChoice = '1A';
        currentStepIndex = 3;
      } else if (normalizedStatus == RmcStatus.return1B.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.returnPath;
        branchChoice = '1B';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.return2.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.returnPath;
        currentStepIndex = 5;
      }
      // Replace branch statuses - new workflow
      else if (normalizedStatus == RmcStatus.waitingReplacementItem.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.replace;
        branchChoice = 'item';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.waitingReplacementParts.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.replace;
        branchChoice = 'parts';
        currentStepIndex = 4;
      }
      // Replace branch statuses - legacy
      else if (normalizedStatus == RmcStatus.replace1A.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.replace;
        branchChoice = 'parts';
        currentStepIndex = 5;
      } else if (normalizedStatus == RmcStatus.replace2A.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.replace;
        branchChoice = 'item';
        currentStepIndex = 5;
      }
      // Repair branch statuses - new workflow
      else if (normalizedStatus == RmcStatus.waitingForRepairKitOrParts.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.repair;
        branchChoice = 'parts';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.bringingItemToServiceCenter.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.repair;
        branchChoice = 'service';
        currentStepIndex = 4;
      }
      // Repair branch statuses - legacy
      else if (normalizedStatus == RmcStatus.repair1A.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.repair;
        branchChoice = 'service';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.repair1B.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.repair;
        branchChoice = 'service';
        currentStepIndex = 5;
      } else if (normalizedStatus == RmcStatus.repair2A.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.repair;
        branchChoice = 'parts';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.repair2B.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.repair;
        branchChoice = 'parts';
        currentStepIndex = 5;
      }
      // Dispose branch statuses - new workflow
      else if (normalizedStatus == RmcStatus.disposingOfItem.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.dispose;
        branchChoice = 'self';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.bringingItemToLocalRetailer.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.dispose;
        branchChoice = 'retailer';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.disposedOfItemAtRetailer.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.dispose;
        branchChoice = 'retailer';
        currentStepIndex = 5;
      }
      // Dispose branch statuses - legacy
      else if (normalizedStatus == RmcStatus.dispose1A.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.dispose;
        branchChoice = '1A';
        currentStepIndex = 3;
      } else if (normalizedStatus == RmcStatus.dispose1B.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.dispose;
        branchChoice = '1B';
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.dispose2A.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.dispose;
        currentStepIndex = 5;
      }
      // Proof branch statuses
      else if (normalizedStatus == RmcStatus.proofSelected.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.proof;
        currentStepIndex = 3;
      } else if (normalizedStatus == RmcStatus.itemDamaged.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.proof;
        currentStepIndex = 4;
      } else if (normalizedStatus == RmcStatus.proofSentToManuf.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.proof;
        currentStepIndex = 5;
      } else if (normalizedStatus == RmcStatus.waitingRefund.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.proof;
        currentStepIndex = 5;
      } else if (normalizedStatus == RmcStatus.receivedRefund.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        selectedBranch = ResolutionBranch.proof;
        currentStepIndex = 5;
      }
      // Completion statuses
      else if (normalizedStatus == RmcStatus.closed.toLowerCase() ||
               normalizedStatus == RmcStatus.completed.toLowerCase()) {
        stoppedUsing = true;
        contactMethod = 'contacted';
        // For closed/completed, default to return path branch
        // This ensures allStepTitles has enough items for index 5
        selectedBranch = ResolutionBranch.returnPath;
        currentStepIndex = 5;
      }
      // Legacy "In Progress -" format (for backward compatibility)
      else if (status.startsWith('In Progress - ')) {
        final subStatus = status.replaceFirst('In Progress - ', '');
        stoppedUsing = true;
        contactMethod = 'contacted';

        if (subStatus == 'Discontinued Use') {
          currentStepIndex = 1;
        } else if (subStatus == 'Contacted Manufacturer') {
          currentStepIndex = 2;
        } else if (subStatus.contains('Return')) {
          selectedBranch = ResolutionBranch.returnPath;
          currentStepIndex = 3;
        } else if (subStatus.contains('Repair')) {
          selectedBranch = ResolutionBranch.repair;
          currentStepIndex = 3;
        } else if (subStatus.contains('Replace')) {
          selectedBranch = ResolutionBranch.replace;
          currentStepIndex = 3;
        } else if (subStatus.contains('Dispose')) {
          selectedBranch = ResolutionBranch.dispose;
          currentStepIndex = 3;
        }
      }
    }
  }

  // Auto-save functionality
  void _startAutoSave() {
    // Auto-save every 30 seconds
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_hasUnsavedChanges && !_isSaving) {
        _saveDraft();
      }
    });
  }

  // Load Proof step data from local storage
  Future<void> _loadProofStepDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _proofStorageKey;

      final purchaseFrom = prefs.getString('${key}_purchaseFrom');
      final purchaseDate = prefs.getString('${key}_purchaseDate');
      final serialNumber = prefs.getString('${key}_serialNumber');
      final pic1Path = prefs.getString('${key}_pic1Path');
      final pic2Path = prefs.getString('${key}_pic2Path');

      if (mounted) {
        setState(() {
          if (purchaseFrom != null && purchaseFrom.isNotEmpty) {
            _purchaseFromController.text = purchaseFrom;
            userPurchasedItemFrom = purchaseFrom;
          }
          if (purchaseDate != null && purchaseDate.isNotEmpty) {
            _purchaseDateController.text = purchaseDate;
            userPurchasedItemDate = purchaseDate;
          }
          if (serialNumber != null && serialNumber.isNotEmpty) {
            _serialNumberController.text = serialNumber;
            userItemSN = serialNumber;
          }
          // Only restore photo paths if the files still exist
          if (pic1Path != null && pic1Path.isNotEmpty && File(pic1Path).existsSync()) {
            userProofPic1Path = pic1Path;
          }
          if (pic2Path != null && pic2Path.isNotEmpty && File(pic2Path).existsSync()) {
            userProofPic2Path = pic2Path;
          }
        });
      }
      debugPrint('Loaded Proof step data from storage for key: $key');
    } catch (e) {
      debugPrint('Failed to load Proof step data from storage: $e');
    }
  }

  // Save Proof step data to local storage
  Future<void> _saveProofStepDataToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _proofStorageKey;

      await prefs.setString('${key}_purchaseFrom', _purchaseFromController.text);
      await prefs.setString('${key}_purchaseDate', _purchaseDateController.text);
      await prefs.setString('${key}_serialNumber', _serialNumberController.text);
      await prefs.setString('${key}_pic1Path', userProofPic1Path ?? '');
      await prefs.setString('${key}_pic2Path', userProofPic2Path ?? '');

      debugPrint('Saved Proof step data to storage for key: $key');
    } catch (e) {
      debugPrint('Failed to save Proof step data to storage: $e');
    }
  }

  // Clear Proof step data from local storage (called when step is completed)
  Future<void> _clearProofStepDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _proofStorageKey;

      await prefs.remove('${key}_purchaseFrom');
      await prefs.remove('${key}_purchaseDate');
      await prefs.remove('${key}_serialNumber');
      await prefs.remove('${key}_pic1Path');
      await prefs.remove('${key}_pic2Path');

      debugPrint('Cleared Proof step data from storage for key: $key');
    } catch (e) {
      debugPrint('Failed to clear Proof step data from storage: $e');
    }
  }

  Future<void> _saveDraft() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _lastSaveError = null;
    });

    try {
      // Only save status updates for now
      // Draft state is preserved in widget state and persisted on status change
      await _updateStatusInApi();

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
          _lastSavedAt = DateTime.now();
          _lastSaveError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _lastSaveError = e.toString();
        });
      }
    }
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _handleBackPress() async {
    if (_hasUnsavedChanges) {
      // Save before leaving
      await _saveDraft();
    }
    return true;
  }

  // Current status getter
  // Status shows what was COMPLETED in the previous step (lags by 1 step)
  String get currentStatus {
    // Completed state (beyond all steps)
    if (currentStepIndex >= allStepTitles.length && selectedBranch != null) {
      return RmcStatus.completed;
    }

    // Pre-workflow steps - status shows what was just completed
    switch (currentStepIndex) {
      case 0:
        return RmcStatus.notStarted; // On step 1, nothing completed yet
      case 1:
        return RmcStatus.stoppedUsing; // On step 2, just completed stopping use
      case 2:
        return RmcStatus.mfrContacted; // On step 3, just completed contacting
      default:
        // Branch-specific steps (step 4+)
        if (selectedBranch != null) {
          return _getBranchStatus();
        }
        return RmcStatus.notStarted;
    }
  }

  // Get specific status for current branch and step
  String _getBranchStatus() {
    final branchStepIndex = currentStepIndex - 3;

    switch (selectedBranch!) {
      case ResolutionBranch.returnPath:
        return _getReturnBranchStatus(branchStepIndex);
      case ResolutionBranch.repair:
        return _getRepairBranchStatus(branchStepIndex);
      case ResolutionBranch.replace:
        return _getReplaceBranchStatus(branchStepIndex);
      case ResolutionBranch.dispose:
        return _getDisposeBranchStatus(branchStepIndex);
      case ResolutionBranch.proof:
        return _getProofBranchStatus(branchStepIndex);
    }
  }

  String _getReturnBranchStatus(int branchStepIndex) {
    // Status shows what was just COMPLETED (previous step)
    switch (branchStepIndex) {
      case 0: // On "Return item Options" step
        return RmcStatus.returnSelected; // Just completed "Choose Path" - Return selected
      case 1: // On "Return Instructions" step
        // Just completed "Return item Options"
        if (branchChoice == 'ship') return RmcStatus.shippingItemsBack; // Shipping Items Back
        if (branchChoice == 'retailer') return RmcStatus.bringingItemToRetailer; // Bringing item to retailer
        return RmcStatus.returnSelected;
      case 2: // On "Complete" step (Step 6)
        // Just completed "Return Instructions"
        if (branchChoice == 'ship') return RmcStatus.shippedItemBack; // Shipped Item Back
        if (branchChoice == 'retailer') return RmcStatus.bringingItemToRetailer; // Still Bringing item to retailer
        return RmcStatus.shippingItemsBack;
      default:
        // Beyond all steps (after clicking "Recall Completed")
        return RmcStatus.return2;
    }
  }

  String _getRepairBranchStatus(int branchStepIndex) {
    // Status shows what was just COMPLETED (previous step)
    switch (branchStepIndex) {
      case 0: // On "Repair item Options" step
        return RmcStatus.repairSelected; // Just completed "Choose Path" - Repair selected
      case 1: // On "Repair Next Steps" step
        // Just completed "Repair item Options"
        if (branchChoice == 'parts') return RmcStatus.waitingForRepairKitOrParts; // Waiting for repair kit or parts
        if (branchChoice == 'service') return RmcStatus.bringingItemToServiceCenter; // Bringing item to service center
        return RmcStatus.repairSelected;
      case 2: // On "Complete" step (Step 6)
        // Just completed "Repair Next Steps"
        // Parts path stays at waiting for repair kit or parts
        if (branchChoice == 'parts') return RmcStatus.waitingForRepairKitOrParts;
        // Service center path stays at bringing item to service center
        if (branchChoice == 'service') return RmcStatus.bringingItemToServiceCenter;
        return RmcStatus.waitingForRepairKitOrParts;
      default:
        // Beyond all steps (after clicking "Recall Completed")
        // Parts path
        if (branchChoice == 'parts') return RmcStatus.repair2B;
        // Service path
        return RmcStatus.repair1B;
    }
  }

  String _getReplaceBranchStatus(int branchStepIndex) {
    // Status shows what was just COMPLETED (previous step)
    switch (branchStepIndex) {
      case 0: // On "Replacement Preference" step
        return RmcStatus.replaceSelected; // Just completed "Choose Path" - Replace selected
      case 1: // On "Delivery Details" step
        // Just completed "Replacement Preference" - waiting for item or parts
        if (branchChoice == 'item') return RmcStatus.waitingReplacementItem;
        if (branchChoice == 'parts') return RmcStatus.waitingReplacementParts;
        return RmcStatus.replaceSelected;
      case 2: // On "Complete" step (Step 6)
        // Just completed "Delivery Details" - received item or parts
        if (branchChoice == 'item') return RmcStatus.replace2A; // Received Replacement Item
        if (branchChoice == 'parts') return RmcStatus.replace1A; // Received Parts
        return RmcStatus.waitingReplacementItem;
      default:
        // Beyond all steps (after clicking "Recall Completed")
        if (branchChoice == 'item') return RmcStatus.replace2A;
        return RmcStatus.replace1A;
    }
  }

  String _getDisposeBranchStatus(int branchStepIndex) {
    // Status shows what was just COMPLETED (previous step)
    switch (branchStepIndex) {
      case 0: // On "Disposal Options" step (Step 4)
        return RmcStatus.disposeSelected; // Just completed "Choose Path" - Dispose selected
      case 1: // On "Disposal Information" step (Step 5)
        // Just completed "Disposal Options"
        if (branchChoice == 'retailer') return RmcStatus.bringingItemToLocalRetailer;
        if (branchChoice == 'self') return RmcStatus.disposingOfItem;
        return RmcStatus.disposeSelected;
      case 2: // On "Complete" step (Step 6)
        // Just completed "Disposal Information"
        if (branchChoice == 'retailer') return RmcStatus.disposedOfItemAtRetailer;
        if (branchChoice == 'self') return RmcStatus.disposingOfItem; // Status stays the same
        return RmcStatus.disposingOfItem;
      default:
        // Beyond all steps (after clicking "Recall Completed")
        if (branchChoice == 'retailer') {
          return RmcStatus.disposedOfItemAtRetailer;
        }
        return RmcStatus.dispose2A;
    }
  }

  String _getProofBranchStatus(int branchStepIndex) {
    // Proof branch status progression:
    // Step 0 (index 3): On "Damage Item" step - just selected Proof
    // Step 1 (index 4): On "Send Proof" step - item damaged
    // Step 2 (index 5): On "Complete" step - proof sent, waiting refund
    switch (branchStepIndex) {
      case 0: // On "Damage Item" step (Step 4)
        return RmcStatus.proofSelected;
      case 1: // On "Send Proof" step (Step 5)
        return RmcStatus.itemDamaged;
      case 2: // On "Complete" step (Step 6)
        return RmcStatus.proofSentToManuf;
      default:
        // Beyond all steps (after clicking "Recall Completed")
        return RmcStatus.receivedRefund;
    }
  }

  List<String> get allStepTitles {
    final steps = List<String>.from(preStepTitles);
    if (selectedBranch != null) {
      steps.addAll(_getBranchSteps());
    }
    return steps;
  }

  List<String> _getBranchSteps() {
    switch (selectedBranch) {
      case ResolutionBranch.returnPath:
        return ['Choose Method', 'Instructions', 'Complete'];
      case ResolutionBranch.repair:
        return ['Pick Repair Method', 'Next Steps', 'Complete'];
      case ResolutionBranch.replace:
        return ['Preference', 'Delivery', 'Complete'];
      case ResolutionBranch.dispose:
        return ['Choose Method', 'Confirm', 'Complete'];
      case ResolutionBranch.proof:
        return ['Damage Item', 'Send Proof', 'Complete'];
      default:
        return [];
    }
  }

  void _goBackStep() {
    if (currentStepIndex > 0) {
      setState(() {
        currentStepIndex--;
        _markAsChanged();
      });
    }
  }

  Future<void> _advanceStep() async {
    setState(() {
      if (currentStepIndex < allStepTitles.length - 1) {
        currentStepIndex++;
      }
      _markAsChanged();
    });

    // Show saving indicator and update status in the API
    setState(() => _isSaving = true);
    try {
      await _updateStatusInApi();
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
          _lastSavedAt = DateTime.now();
        });
      }
    } catch (e) {
      // Error already shown in _updateStatusInApi
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateStatusInApi() async {
    try {
      String newStatus = currentStatus;

      // Check if we have a valid recall database ID
      if (widget.recall.databaseId == null) {
        debugPrint('Warning: Recall databaseId is null, cannot save to API');
        return;
      }

      // If enrollment doesn't exist yet, create it with current status
      if (_enrollment == null) {
        _enrollment = await ApiService().enrollRecallInRmc(
          recallId: widget.recall.databaseId!,
          rmcStatus: newStatus,
        );
        debugPrint('Created new enrollment with status: $newStatus');
      } else {
        // Update existing enrollment status
        _enrollment = await ApiService().updateRmcEnrollmentStatus(
          _enrollment!.id,
          newStatus,
        );
        debugPrint('Updated enrollment status to: $newStatus');
      }

      // Update state to reflect the new enrollment
      if (mounted) {
        setState(() {
          _lastSaveError = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to save progress: $e');
      // Show error to user with retry option
      if (mounted) {
        setState(() {
          _lastSaveError = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save progress: ${e.toString().substring(0, e.toString().length > 50 ? 50 : e.toString().length)}'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _updateStatusInApi(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _selectBranch(ResolutionBranch branch) async {
    setState(() {
      selectedBranch = branch;
      currentStepIndex = 3; // Move to first branch step
      branchChoice = null; // Reset branch choice
      _markAsChanged();
    });

    // Show saving indicator and update status AND branch in the API
    setState(() => _isSaving = true);
    try {
      // Determine the branch name string
      String branchName;
      switch (branch) {
        case ResolutionBranch.returnPath:
          branchName = 'Return';
          break;
        case ResolutionBranch.repair:
          branchName = 'Repair';
          break;
        case ResolutionBranch.replace:
          branchName = 'Replace';
          break;
        case ResolutionBranch.dispose:
          branchName = 'Dispose';
          break;
        case ResolutionBranch.proof:
          branchName = 'Proof';
          break;
      }

      String newStatus = currentStatus;

      // If enrollment doesn't exist yet, create it with current status
      _enrollment ??= await ApiService().enrollRecallInRmc(
        recallId: widget.recall.databaseId!,
        rmcStatus: newStatus,
      );

      // Update enrollment with both status and resolution branch
      _enrollment = await ApiService().updateRmcEnrollment(
        enrollmentId: _enrollment!.id,
        status: newStatus,
        resolutionBranch: branchName,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
          _lastSavedAt = DateTime.now();
          _lastSaveError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _lastSaveError = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save progress'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _selectBranch(branch),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final canPop = await _handleBackPress();
          if (canPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final canPop = await _handleBackPress();
              if (canPop && mounted) {
                navigator.pop();
              }
            },
          ),
          title: const Text(
            'Recall Resolution',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            _buildSaveIndicator(),
          ],
        ),
      body: SingleChildScrollView(
        controller: hideOnScrollController,
        child: Container(
          color: AppColors.primary,
          child: Column(
            children: [
              // Recall Card based on agency
              Padding(
                padding: const EdgeInsets.all(16),
                child: widget.recall.agency.toUpperCase() == 'USDA'
                    ? SmallUsdaRecallCard(recall: widget.recall)
                    : SmallFdaRecallCard(recall: widget.recall),
              ),
              // Current Status Row
              _buildStatusRow(),
              // Progress Stepper
              _buildStepper(),
              // Spacing below status row
              const SizedBox(height: 15),
              // Main Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
          backgroundColor: AppColors.secondary,
          selectedItemColor: AppColors.accentBlue,
          unselectedItemColor: AppColors.textTertiary,
          currentIndex: 1, // Recalls tab selected
          elevation: 8,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 0),
                  ),
                  (route) => false,
                );
                break;
              case 1:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 1),
                  ),
                  (route) => false,
                );
                break;
              case 2:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 2),
                  ),
                  (route) => false,
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSaveIndicator() {
    if (_isSaving) {
      return const Padding(
        padding: EdgeInsets.only(right: 16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Saving...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    } else if (_lastSaveError != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 4),
            TextButton(
              onPressed: _saveDraft,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    } else if (_lastSavedAt != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastSavedAt!);
      String timeAgo;
      if (diff.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else {
        timeAgo = '${diff.inHours}h ago';
      }

      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 18),
            const SizedBox(width: 4),
            Text(
              timeAgo,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button (only show if not on first step)
              if (currentStepIndex > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 20),
                  onPressed: _goBackStep,
                  tooltip: 'Previous step',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                const SizedBox(width: 0),
              if (currentStepIndex > 0)
                const SizedBox(width: 8),
              Text(
                'Step ${currentStepIndex + 1} of 6',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Step indicators (always show 6 steps)
          Row(
            children: List.generate(
              6,
              (index) {
                final isActive = index == currentStepIndex;
                final isDone = index < currentStepIndex;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDone || isActive
                                ? AppColors.accentBlue
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < 5)
                        const SizedBox(width: 4),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            'Current Status: ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            currentStatus,
            style: const TextStyle(
              color: AppColors.accentBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    // Pre-steps
    if (currentStepIndex == 0) return _buildStopUsingStep();
    if (currentStepIndex == 1) return _buildContactStep();
    if (currentStepIndex == 2) return _buildChoosePathStep();

    // Branch steps
    if (selectedBranch != null) {
      final branchStepIndex = currentStepIndex - 3;
      switch (selectedBranch!) {
        case ResolutionBranch.returnPath:
          return _buildReturnStep(branchStepIndex);
        case ResolutionBranch.repair:
          return _buildRepairStep(branchStepIndex);
        case ResolutionBranch.replace:
          return _buildReplaceStep(branchStepIndex);
        case ResolutionBranch.dispose:
          return _buildDisposeStep(branchStepIndex);
        case ResolutionBranch.proof:
          return _buildProofStep(branchStepIndex);
      }
    }

    return const SizedBox.shrink();
  }

  // ===== PRE-STEPS =====

  Widget _buildStopUsingStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Discontinue using the product now',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Product: ${widget.recall.productName}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Brand: ${widget.recall.brandName}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Unplug and store safely away from children and pets.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  stoppedUsing = true;
                });
                _advanceStep();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'I Stopped Using It',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact the manufacturer',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get official instructions for this recall',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          if (widget.recall.establishmentManufacturerContactPhone.isNotEmpty) ...[
            _buildChoiceCard(
              'Phone',
              Icons.phone,
              contactMethod == 'phone',
              () {
                setState(() {
                  contactMethod = 'phone';
                  _markAsChanged();
                });
                launchUrl(Uri.parse('tel:${widget.recall.establishmentManufacturerContactPhone}'));
              },
            ),
            const SizedBox(height: 12),
          ],
          if (widget.recall.establishmentManufacturerContactEmail.isNotEmpty) ...[
            _buildChoiceCard(
              'Email',
              Icons.email,
              contactMethod == 'email',
              () {
                setState(() {
                  contactMethod = 'email';
                  _markAsChanged();
                });
                launchUrl(
                    Uri.parse('mailto:${widget.recall.establishmentManufacturerContactEmail}'));
              },
            ),
            const SizedBox(height: 12),
          ],
          if (widget.recall.establishmentManufacturerWebsite.isNotEmpty) ...[
            _buildChoiceCard(
              'Website',
              Icons.language,
              contactMethod == 'website',
              () {
                setState(() {
                  contactMethod = 'website';
                  _markAsChanged();
                });
                launchUrl(Uri.parse(widget.recall.establishmentManufacturerWebsite));
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              // Check if all contact fields are empty
              final allFieldsEmpty =
                  widget.recall.establishmentManufacturerContactPhone.isEmpty &&
                  widget.recall.establishmentManufacturerContactEmail.isEmpty &&
                  widget.recall.establishmentManufacturerWebsite.isEmpty;

              // Enable button if contact method selected OR all fields are empty
              final canContinue = contactMethod != null || allFieldsEmpty;

              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canContinue ? _advanceStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChoosePathStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your resolution path',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Based on manufacturer guidance',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildBranchCard(
          'Return',
          'Ship back or bring to retailer for refund',
          AppColors.accentBlue,
          Icons.keyboard_return,
          () => _selectBranch(ResolutionBranch.returnPath),
        ),
        const SizedBox(height: 12),
        _buildBranchCard(
          'Repair',
          'Receive parts or visit service center',
          AppColors.success,
          Icons.build,
          () => _selectBranch(ResolutionBranch.repair),
        ),
        const SizedBox(height: 12),
        _buildBranchCard(
          'Replace',
          'Get a replacement item or parts',
          AppColors.warning,
          Icons.swap_horiz,
          () => _selectBranch(ResolutionBranch.replace),
        ),
        const SizedBox(height: 12),
        _buildBranchCard(
          'Dispose',
          'Dispose or take to retailer for refund',
          AppColors.error,
          Icons.delete_outline,
          () => _selectBranch(ResolutionBranch.dispose),
        ),
        const SizedBox(height: 12),
        _buildBranchCard(
          'Proof',
          'Submit proof of damage for refund',
          Colors.purple,
          Icons.camera_alt,
          () => _selectBranch(ResolutionBranch.proof),
        ),
      ],
    );
  }

  // ===== BRANCH STEPS =====

  Widget _buildReturnStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Choose Method
        return _buildBranchChoiceStep(
          'Return item Options:',
          [
            ChoiceOption('ship', 'Ship item back', Icons.local_shipping),
            ChoiceOption('retailer', 'Bring to local retailer', Icons.store),
          ],
        );
      case 1: // Instructions
        // Build retailer info string
        String retailerInfo = '';
        if (widget.recall.soldBy.isNotEmpty && widget.recall.distributor.isNotEmpty) {
          retailerInfo = '${widget.recall.soldBy}, ${widget.recall.distributor}';
        } else if (widget.recall.soldBy.isNotEmpty) {
          retailerInfo = widget.recall.soldBy;
        } else if (widget.recall.distributor.isNotEmpty) {
          retailerInfo = widget.recall.distributor;
        }

        return _buildInstructionsStep(
          'Return Instructions',
          branchChoice == 'ship'
              ? 'Print a shipping label, box up the item and ship it back to the manufacturer.'
              : 'Take the item to your nearest retailer. Take any receipts you may have.${retailerInfo.isNotEmpty ? ' Retailers noted in the recall include: $retailerInfo' : ''}',
          [], // No action buttons
        );
      case 2: // Complete
        return _buildCompleteStep('Return');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRepairStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Repair Options
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Repair item Options:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Follow the instruction given by the manufacture and choose an option. For repair kits or parts, ensure the manufacturer has your up-to-date shipping information.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildChoiceCard(
                'Receive repair kit or parts',
                Icons.inbox,
                branchChoice == 'parts',
                () => setState(() {
                  branchChoice = 'parts';
                  _markAsChanged();
                }),
              ),
              const SizedBox(height: 12),
              _buildChoiceCard(
                'Visit service center',
                Icons.home_repair_service,
                branchChoice == 'service',
                () => setState(() {
                  branchChoice = 'service';
                  _markAsChanged();
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: branchChoice != null ? _advanceStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 1: // Next Steps
        return _buildInstructionsStep(
          'Repair Next Steps',
          branchChoice == 'parts'
              ? 'You should receive either parts or a kit from the manufacturer for this recalled item.'
              : 'Visit an authorized service center to have your item repaired.',
          [], // No action buttons
        );
      case 2: // Complete
        return _buildCompleteStep('Repair');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReplaceStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Replacement Preference
        return _buildBranchChoiceStep(
          'Select which Replacement option the Manufacturer will follow (item or parts)',
          [
            ChoiceOption('item', 'Will receive replacement item from manufacturer', Icons.inventory_2),
            ChoiceOption('parts', 'Will receive replacement parts from manufacturer', Icons.build_circle),
          ],
        );
      case 1: // Delivery Details
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update the status of your Replace recall',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    // Update to the appropriate status based on choice
                    final status = branchChoice == 'item'
                        ? RmcStatus.replace2A
                        : RmcStatus.replace1A;
                    _enrollment = await ApiService().updateRmcEnrollmentStatus(
                      _enrollment!.id,
                      status,
                    );
                    _advanceStep();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    branchChoice == 'item'
                        ? 'Received Replacement Item'
                        : 'Received Replacement Parts',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 2: // Complete
        return _buildCompleteStep('Replace');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDisposeStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Disposal Options
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Disposal Options:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dispose of recalled item per manufacturer instructions or bring the recalled item to your local retailer',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildChoiceCard(
                'Dispose of item',
                Icons.recycling,
                branchChoice == 'self',
                () => setState(() {
                  branchChoice = 'self';
                  _markAsChanged();
                }),
              ),
              const SizedBox(height: 12),
              _buildChoiceCard(
                'Bring to local retailer',
                Icons.store,
                branchChoice == 'retailer',
                () => setState(() {
                  branchChoice = 'retailer';
                  _markAsChanged();
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: branchChoice != null ? _advanceStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 1: // Disposal Information
        return _buildInstructionsStep(
          'Disposal Information',
          branchChoice == 'self'
              ? 'Refer to regulatory instructions or manufacturer info to ensure safe disposal of this recalled item.'
              : 'Take the item to your nearest retailer for safe disposal.',
          [], // No action buttons
        );
      case 2: // Complete
        return _buildCompleteStep('Dispose');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProofStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Damage Item per Manufacturer Instructions
        return _buildProofDamageStep();
      case 1: // Send Proof to Manufacturer
        return _buildProofSendStep();
      case 2: // Complete
        return _buildProofCompleteStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProofDamageStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Damage Item Per Manufacturer Instructions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Remedy field from recall data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Remedy Instructions:',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.recall.remedy.isNotEmpty
                      ? widget.recall.remedy
                      : 'Please refer to the manufacturer\'s website or contact them directly for specific damage instructions.',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'After damaging the item as instructed, you will need to take photos as proof.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _advanceStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'I Have Damaged The Item',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofSendStep() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Proof to Manufacturer',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete the following information to send proof via email.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Sub-task A: Where purchased
            _buildProofSubtaskHeader('A', 'Where did you purchase this item?'),
            const SizedBox(height: 8),
            TextField(
              controller: _purchaseFromController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Amazon, Walmart, Target',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.primary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
                ),
              ),
              onChanged: (value) {
                userPurchasedItemFrom = value;
                _markAsChanged();
                _saveProofStepDataToStorage();
              },
            ),
            const SizedBox(height: 20),

            // Sub-task B: When purchased
            _buildProofSubtaskHeader('B', 'When did you purchase this item?'),
            const SizedBox(height: 4),
            const Text(
              'If you don\'t know exactly when, give a general answer. The more specific you are the sooner you will probably receive your refund.',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _purchaseDateController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., March 2024, Last summer',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.primary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
                ),
              ),
              onChanged: (value) {
                userPurchasedItemDate = value;
                _markAsChanged();
                _saveProofStepDataToStorage();
              },
            ),
            const SizedBox(height: 20),

            // Sub-task C: Serial Number
            _buildProofSubtaskHeader('C', 'Serial Number (Optional)'),
            const SizedBox(height: 4),
            const Text(
              'If the item has a serial number, enter it here so the manufacturer can verify your item is included in their recall.',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _serialNumberController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter serial number if available',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.primary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
                ),
              ),
              onChanged: (value) {
                userItemSN = value;
                _markAsChanged();
                _saveProofStepDataToStorage();
              },
            ),
            const SizedBox(height: 20),

            // Sub-task D: Take 2 photos
            _buildProofSubtaskHeader('D', 'Take 2 Photos of the Damaged Item'),
            const SizedBox(height: 4),
            const Text(
              'These pictures will be included in your refund email to the manufacturer.',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoCard(
                    'Photo 1',
                    userProofPic1Path,
                    () => _pickImage(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoCard(
                    'Photo 2',
                    userProofPic2Path,
                    () => _pickImage(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sub-task E: Build and send email
            _buildProofSubtaskHeader('E', 'Send Email to Manufacturer'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canSendProofEmail() ? _sendProofEmail : null,
                icon: const Icon(Icons.email, color: AppColors.textPrimary),
                label: const Text(
                  'Build & Send Email',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canSendProofEmail() ? () async {
                  // Save proof data to backend with photos
                  setState(() => _isSaving = true);
                  try {
                    if (_enrollment != null) {
                      _enrollment = await ApiService().updateRmcEnrollmentWithProof(
                        enrollmentId: _enrollment!.id,
                        status: RmcStatus.proofSentToManuf,
                        proofPurchaseLocation: _purchaseFromController.text,
                        proofPurchaseDate: _purchaseDateController.text,
                        proofSerialNumber: _serialNumberController.text,
                        proofPhoto1Path: userProofPic1Path,
                        proofPhoto2Path: userProofPic2Path,
                      );
                    }

                    // Clear local data since proof has been saved to backend
                    await _clearProofStepDataFromStorage();

                    if (mounted) {
                      setState(() {
                        _isSaving = false;
                        currentStepIndex++;
                        _hasUnsavedChanges = false;
                        _lastSavedAt = DateTime.now();
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save proof data: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofNextStepItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProofSubtaskHeader(String letter, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accentBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(String label, String? imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imagePath != null ? AppColors.success : AppColors.border,
            width: 2,
          ),
        ),
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt,
                    color: AppColors.textTertiary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const Text(
                    'Tap to add',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage(int photoNumber) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Photo Source',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.accentBlue),
                title: const Text('Camera', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.accentBlue),
                title: const Text('Gallery', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (photoNumber == 1) {
            userProofPic1Path = pickedFile.path;
          } else {
            userProofPic2Path = pickedFile.path;
          }
          _markAsChanged();
        });
        // Save photo paths to local storage
        _saveProofStepDataToStorage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _canSendProofEmail() {
    return _purchaseFromController.text.isNotEmpty &&
        _purchaseDateController.text.isNotEmpty &&
        userProofPic1Path != null &&
        userProofPic2Path != null;
  }

  Future<void> _sendProofEmail() async {
    // Get user info (if available from enrollment or settings)
    final userName = _enrollment?.username ?? 'RecallSentry User';

    // Build email body
    final emailBody = '''
Hi ${widget.recall.brandName},

I purchased a ${widget.recall.productName} from ${_purchaseFromController.text} on ${_purchaseDateController.text}. The item is not being used, it has been put aside, it has been damaged per your instructions and pictures are attached as proof. Please see the recalled item details below and let me know how I will receive my refund for this item.

Agency: ${widget.recall.agency}
Recall Number: ${widget.recall.fieldRecallNumber}
Brand Name: ${widget.recall.brandName}
Item: ${widget.recall.productName}
Serial Number: ${_serialNumberController.text.isNotEmpty ? _serialNumberController.text : 'N/A'}
Recall Date: ${widget.recall.dateIssued.toString().split(' ')[0]}
Where Purchased: ${_purchaseFromController.text}
Purchase Date: ${_purchaseDateController.text}

Recall Link for reference: ${widget.recall.recallUrl}

Thank you,
$userName
''';

    // Get manufacturer email
    final manufacturerEmail = widget.recall.establishmentManufacturerContactEmail.isNotEmpty
        ? widget.recall.establishmentManufacturerContactEmail
        : '';

    final subject = 'Refund for recalled item - ${widget.recall.productName}';

    // Build attachment list from proof photos
    final List<String> attachments = [];
    if (userProofPic1Path != null) {
      attachments.add(userProofPic1Path!);
    }
    if (userProofPic2Path != null) {
      attachments.add(userProofPic2Path!);
    }

    // Create email with attachments using flutter_email_sender
    final Email email = Email(
      body: emailBody,
      subject: subject,
      recipients: manufacturerEmail.isNotEmpty ? [manufacturerEmail] : [],
      attachmentPaths: attachments,
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email opened with photos attached!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Fallback to mailto if flutter_email_sender fails
      debugPrint('FlutterEmailSender failed: $e, falling back to mailto');
      await _sendProofEmailFallback(emailBody, subject, manufacturerEmail);
    }
  }

  Future<void> _sendProofEmailFallback(String body, String subject, String recipient) async {
    // Encode body properly for mailto
    final encodedBody = Uri.encodeComponent(body);
    final encodedSubject = Uri.encodeComponent(subject);

    final mailtoString = 'mailto:$recipient?subject=$encodedSubject&body=$encodedBody';
    final mailtoUri = Uri.parse(mailtoString);

    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email opened! Please manually attach the 2 proof photos.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open email: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildProofCompleteStep() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Proof Submitted Successfully',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'You have sent proof of damage to the manufacturer.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Steps:',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProofNextStepItem('4', 'Set the recalled item aside where it cannot be used again'),
                const SizedBox(height: 8),
                _buildProofNextStepItem('5', 'Wait for your refund from the manufacturer'),
                const SizedBox(height: 8),
                _buildProofNextStepItem('6', 'After receiving refund, dispose of the item properly'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                // Mark as completed and navigate to RMC status page
                setState(() => _isSaving = true);
                try {
                  if (_enrollment != null) {
                    _enrollment = await ApiService().updateRmcEnrollmentStatus(
                      _enrollment!.id,
                      RmcStatus.completed,
                    );
                  }

                  // Clear local Proof step data since recall is completed
                  await _clearProofStepDataFromStorage();

                  if (mounted) {
                    setState(() => _isSaving = false);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RmcStatusPage(),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to mark as completed: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Recall Completed',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== HELPER WIDGETS =====

  Widget _buildChoiceCard(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBlue.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentBlue : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.accentBlue : Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.accentBlue,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(String title, String subtitle, Color color,
      IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchChoiceStep(
      String question, List<ChoiceOption> options) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...options.map((option) {
            final selected = branchChoice == option.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChoiceCard(
                option.label,
                option.icon,
                selected,
                () => setState(() {
                  branchChoice = option.key;
                  _markAsChanged();
                }),
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: branchChoice != null ? _advanceStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsStep(
      String title, String instructions, List<ActionButton> actions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            instructions,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...actions.map((action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: action.onTap,
                    icon: Icon(action.icon, color: AppColors.accentBlue),
                    label: Text(
                      action.label,
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: AppColors.accentBlue, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _advanceStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep(String pathName) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Mark this Recall as completed',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'You completed the $pathName process for your item.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                // Mark as completed and navigate to RMC status page
                setState(() => _isSaving = true);
                try {
                  // Update status to Completed
                  if (_enrollment != null) {
                    _enrollment = await ApiService().updateRmcEnrollmentStatus(
                      _enrollment!.id,
                      RmcStatus.completed,
                    );
                  }

                  if (mounted) {
                    setState(() => _isSaving = false);
                    // Navigate to RMC status page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RmcStatusPage(),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to mark as completed: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Recall Completed',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== HELPER CLASSES =====

class ChoiceOption {
  final String key;
  final String label;
  final IconData icon;

  ChoiceOption(this.key, this.label, this.icon);
}

class ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  ActionButton(this.label, this.icon, this.onTap);
}
