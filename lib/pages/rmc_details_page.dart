import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../models/rmc_enrollment.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/small_fda_recall_card.dart';
import '../widgets/small_usda_recall_card.dart';
import 'main_navigation.dart';
import '../services/api_service.dart';

enum ResolutionBranch { returnPath, repair, replace, dispose }

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

class _RmcDetailsPageState extends State<RmcDetailsPage> {
  // RMC Enrollment tracking
  RmcEnrollment? _enrollment;

  // Pre-step states
  bool stoppedUsing = false;
  String? contactMethod;
  ResolutionBranch? selectedBranch;

  // Branch-specific states
  String? branchChoice;

  // Current step tracking
  int currentStepIndex = 0;
  final List<String> preStepTitles = ['Stop Using', 'Contact', 'Choose Path'];

  @override
  void initState() {
    super.initState();
    _enrollment = widget.enrollment;
    _initializeFromEnrollment();
  }

  void _initializeFromEnrollment() {
    // If we have an existing enrollment, restore its state
    if (_enrollment != null) {
      final status = _enrollment!.status;
      print('📋 Initializing from enrollment status: $status');

      // Map backend status to workflow state
      switch (status) {
        // Pre-steps
        case 'Not Started':
        case 'Open':
          // Keep defaults (step 0, nothing selected)
          currentStepIndex = 0;
          break;

        case 'Stopped Using':
          stoppedUsing = true;
          currentStepIndex = 1;
          break;

        case 'Mfr Contacted':
          stoppedUsing = true;
          contactMethod = 'contacted';
          currentStepIndex = 2;
          break;

        // Return branch
        case 'Return 1A: Brought to local Retailer':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.returnPath;
          branchChoice = '1A';
          currentStepIndex = 3; // Step: Choose Method (completed)
          break;

        case 'Return 1B: Item Shipped Back':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.returnPath;
          branchChoice = '1B';
          currentStepIndex = 4; // Step: Instructions
          break;

        case 'Return 2: Received Refund':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.returnPath;
          currentStepIndex = 5; // Step: Complete
          break;

        // Replace branch
        case 'Replace 1A: Received Parts':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.replace;
          branchChoice = '1A';
          currentStepIndex = 3; // Step: Preference (completed)
          break;

        case 'Replace 2A: Received Replacement Item':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.replace;
          currentStepIndex = 5; // Step: Complete
          break;

        // Repair branch
        case 'Repair 1A: Brought to Service Center':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.repair;
          branchChoice = '1A';
          currentStepIndex = 3; // Step: Pick Fix Method (completed)
          break;

        case 'Repair 1B: Item Repaired by Service Center':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.repair;
          branchChoice = '1B';
          currentStepIndex = 4; // Step: Next Steps
          break;

        case 'Repair 2A: Received Repair Kit or Parts':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.repair;
          branchChoice = '2A';
          currentStepIndex = 4; // Step: Next Steps
          break;

        case 'Repair 2B: Item Repaired by User':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.repair;
          branchChoice = '2B';
          currentStepIndex = 5; // Step: Complete
          break;

        // Dispose branch
        case 'Dispose 1A: Brought to local Retailer':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.dispose;
          branchChoice = '1A';
          currentStepIndex = 3; // Step: Choose Method (completed)
          break;

        case 'Dispose 1B: Received Refund':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.dispose;
          branchChoice = '1B';
          currentStepIndex = 4; // Step: Confirm
          break;

        case 'Dispose 2A: Disposed of Item':
          stoppedUsing = true;
          contactMethod = 'contacted';
          selectedBranch = ResolutionBranch.dispose;
          currentStepIndex = 5; // Step: Complete
          break;

        // Completed
        case 'Closed':
        case 'Completed':
          stoppedUsing = true;
          contactMethod = 'contacted';
          // For closed/completed, we need to determine which branch was used
          // For now, just set to a completed state at the end
          currentStepIndex = 5;
          break;

        // Legacy "In Progress -" format (for backward compatibility)
        default:
          if (status.startsWith('In Progress - ')) {
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
          break;
      }

      print('✅ Initialized: stoppedUsing=$stoppedUsing, contactMethod=$contactMethod, branch=$selectedBranch, branchChoice=$branchChoice, step=$currentStepIndex');
    }
  }

  // Current status getter
  String get currentStatus {
    // Completed state
    if (currentStepIndex >= allStepTitles.length - 1 && selectedBranch != null) {
      return 'Completed';
    }

    // Step-specific statuses
    switch (currentStepIndex) {
      case 0:
        return stoppedUsing ? 'In Progress - Discontinued Use' : 'Not Started';
      case 1:
        return 'In Progress - Contacted Manufacturer';
      case 2:
        return 'In Progress - Choosing Resolution Path';
      default:
        // Branch-specific steps
        if (selectedBranch != null) {
          return 'In Progress - ${_getBranchName()}';
        }
        return 'Not Started';
    }
  }

  String _getBranchName() {
    switch (selectedBranch) {
      case ResolutionBranch.returnPath:
        return 'Return';
      case ResolutionBranch.repair:
        return 'Repair';
      case ResolutionBranch.replace:
        return 'Replace';
      case ResolutionBranch.dispose:
        return 'Dispose';
      default:
        return '';
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
        return ['Pick Fix Method', 'Next Steps', 'Complete'];
      case ResolutionBranch.replace:
        return ['Preference', 'Delivery', 'Complete'];
      case ResolutionBranch.dispose:
        return ['Choose Method', 'Confirm', 'Complete'];
      default:
        return [];
    }
  }

  Future<void> _advanceStep() async {
    setState(() {
      if (currentStepIndex < allStepTitles.length - 1) {
        currentStepIndex++;
      }
    });

    // Update status in the API based on current step
    await _updateStatusInApi();
  }

  Future<void> _updateStatusInApi() async {
    try {
      String newStatus = currentStatus;

      // If enrollment doesn't exist yet, create it with current status
      if (_enrollment == null) {
        _enrollment = await ApiService().enrollRecallInRmc(
          recallId: widget.recall.databaseId!,
          status: newStatus,
        );
        print('✅ Successfully enrolled recall in RMC with status: $newStatus');
      } else {
        // Update existing enrollment status
        _enrollment = await ApiService().updateRmcEnrollmentStatus(
          _enrollment!.id,
          newStatus,
        );
        print('✅ Successfully updated enrollment status to: $newStatus');
      }

      // Update state to reflect the new enrollment
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently fail - don't disrupt user experience
      print('Failed to update status: $e');
    }
  }

  Future<void> _selectBranch(ResolutionBranch branch) async {
    setState(() {
      selectedBranch = branch;
      currentStepIndex = 3; // Move to first branch step
      branchChoice = null; // Reset branch choice
    });

    // Update status in the API when branch is selected
    await _updateStatusInApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A4A5C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Recall Resolution',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF1D3547),
        child: Column(
          children: [
            // Recall Card based on agency
            Padding(
              padding: const EdgeInsets.all(16),
              child: widget.recall.agency.toUpperCase() == 'USDA'
                  ? SmallUsdaRecallCard(recall: widget.recall)
                  : SmallFdaRecallCard(recall: widget.recall),
            ),
            // Progress Stepper
            _buildStepper(),
            // Current Status Row
            _buildStatusRow(),
            // Spacing below status row
            const SizedBox(height: 15),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C3E50),
        selectedItemColor: const Color(0xFF64B5F6),
        unselectedItemColor: Colors.white54,
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
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: const Color(0xFF2A4A5C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${currentStepIndex + 1} of 6',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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
                                ? const Color(0xFF5DADE2)
                                : Colors.white24,
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
          const SizedBox(height: 12),
          Text(
            allStepTitles[currentStepIndex],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
      color: const Color(0xFF2A4A5C),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Current Status:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            currentStatus,
            style: const TextStyle(
              color: Color(0xFF5DADE2),
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
      }
    }

    return const SizedBox.shrink();
  }

  // ===== PRE-STEPS =====

  Widget _buildStopUsingStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF9800),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Discontinue using the product now',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Product: ${widget.recall.productName}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Brand: ${widget.recall.brandName}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Unplug and store safely away from children and pets.',
            style: TextStyle(
              color: Colors.white,
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
                backgroundColor: const Color(0xFF5DADE2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'I Stopped Using It',
                style: TextStyle(
                  color: Colors.white,
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
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact the manufacturer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get official instructions for this recall',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          _buildChoiceCard(
            'Phone',
            Icons.phone,
            contactMethod == 'phone',
            () {
              setState(() => contactMethod = 'phone');
              if (widget.recall.establishmentManufacturerContactPhone.isNotEmpty) {
                launchUrl(Uri.parse('tel:${widget.recall.establishmentManufacturerContactPhone}'));
              }
            },
          ),
          const SizedBox(height: 12),
          _buildChoiceCard(
            'Email',
            Icons.email,
            contactMethod == 'email',
            () {
              setState(() => contactMethod = 'email');
              if (widget.recall.establishmentManufacturerContactEmail.isNotEmpty) {
                launchUrl(
                    Uri.parse('mailto:${widget.recall.establishmentManufacturerContactEmail}'));
              }
            },
          ),
          const SizedBox(height: 12),
          _buildChoiceCard(
            'Website',
            Icons.language,
            contactMethod == 'website',
            () {
              setState(() => contactMethod = 'website');
              if (widget.recall.establishmentManufacturerWebsite.isNotEmpty) {
                launchUrl(Uri.parse(widget.recall.establishmentManufacturerWebsite));
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: contactMethod != null ? _advanceStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5DADE2),
                disabledBackgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
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

  Widget _buildChoosePathStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A4A5C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your resolution path',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Based on manufacturer guidance',
                style: TextStyle(
                  color: Colors.white70,
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
          const Color(0xFF5DADE2),
          Icons.keyboard_return,
          () => _selectBranch(ResolutionBranch.returnPath),
        ),
        const SizedBox(height: 12),
        _buildBranchCard(
          'Repair',
          'Receive parts or visit service center',
          const Color(0xFF4CAF50),
          Icons.build,
          () => _selectBranch(ResolutionBranch.repair),
        ),
        const SizedBox(height: 12),
        _buildBranchCard(
          'Replace',
          'Get a replacement item or parts',
          const Color(0xFFFF9800),
          Icons.swap_horiz,
          () => _selectBranch(ResolutionBranch.replace),
        ),
        const SizedBox(height: 12),
        _buildBranchCard(
          'Dispose',
          'Dispose or take to retailer for refund',
          const Color(0xFFE53935),
          Icons.delete_outline,
          () => _selectBranch(ResolutionBranch.dispose),
        ),
      ],
    );
  }

  // ===== BRANCH STEPS =====

  Widget _buildReturnStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Choose Method
        return _buildBranchChoiceStep(
          'How do you want to return?',
          [
            ChoiceOption('ship', 'Ship item back', Icons.local_shipping),
            ChoiceOption('retailer', 'Bring to local retailer', Icons.store),
          ],
        );
      case 1: // Instructions
        return _buildInstructionsStep(
          'Return Instructions',
          branchChoice == 'ship'
              ? 'Print the return label and ship the item back to the manufacturer.'
              : 'Take the item to your nearest retailer for a full refund.',
          [
            if (branchChoice == 'ship')
              ActionButton('Get Shipping Label', Icons.print, () {
                // Open label URL
              }),
            if (branchChoice == 'retailer')
              ActionButton('Find Store', Icons.map, () {
                // Open map
              }),
          ],
        );
      case 2: // Complete
        return _buildCompleteStep('Return');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRepairStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Pick Fix Method
        return _buildBranchChoiceStep(
          'How do you prefer to fix?',
          [
            ChoiceOption('parts', 'Receive repair kit or parts', Icons.inbox),
            ChoiceOption(
                'service', 'Visit service center', Icons.home_repair_service),
          ],
        );
      case 1: // Next Steps
        return _buildInstructionsStep(
          'Repair Next Steps',
          branchChoice == 'parts'
              ? 'A repair kit will be shipped to you with detailed instructions.'
              : 'Visit an authorized service center to have your item repaired.',
          [
            if (branchChoice == 'service')
              ActionButton('Find Service Center', Icons.map, () {
                // Open map
              }),
          ],
        );
      case 2: // Complete
        return _buildCompleteStep('Repair');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReplaceStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Preference
        return _buildBranchChoiceStep(
          'Replacement preference',
          [
            ChoiceOption('item', 'Receive replacement item', Icons.inventory),
            ChoiceOption('parts', 'Receive replacement parts', Icons.build),
          ],
        );
      case 1: // Delivery
        return _buildInstructionsStep(
          'Delivery Details',
          branchChoice == 'item'
              ? 'A replacement item will be shipped to your address.'
              : 'Replacement parts will be shipped to your address.',
          [],
        );
      case 2: // Complete
        return _buildCompleteStep('Replace');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDisposeStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Choose Method
        return _buildBranchChoiceStep(
          'Choose disposal method',
          [
            ChoiceOption(
                'self', 'Dispose of item (instructions)', Icons.recycling),
            ChoiceOption('retailer', 'Bring to local retailer', Icons.store),
          ],
        );
      case 1: // Confirm
        return _buildInstructionsStep(
          'Disposal Confirmation',
          branchChoice == 'self'
              ? 'Follow safe disposal instructions for this product.'
              : 'Take the item to your nearest retailer for safe disposal and refund.',
          [
            if (branchChoice == 'self')
              ActionButton('Open Disposal Guide', Icons.description, () {
                // Open guide
              }),
            if (branchChoice == 'retailer')
              ActionButton('Find Store', Icons.map, () {
                // Open map
              }),
          ],
        );
      case 2: // Complete
        return _buildCompleteStep('Dispose');
      default:
        return const SizedBox.shrink();
    }
  }

  // ===== HELPER WIDGETS =====

  Widget _buildChoiceCard(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5DADE2).withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF5DADE2) : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF5DADE2) : Colors.white70,
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
                color: Color(0xFF5DADE2),
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
          color: const Color(0xFF2A4A5C),
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
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
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
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
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
                () => setState(() => branchChoice = option.key),
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
                backgroundColor: const Color(0xFF5DADE2),
                disabledBackgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
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
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            instructions,
            style: const TextStyle(
              color: Colors.white,
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
                    icon: Icon(action.icon, color: const Color(0xFF5DADE2)),
                    label: Text(
                      action.label,
                      style: const TextStyle(
                        color: Color(0xFF5DADE2),
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: Color(0xFF5DADE2), width: 2),
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
                backgroundColor: const Color(0xFF5DADE2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
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
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50),
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'All Set!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You completed the $pathName process.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Follow the guidance from your chosen path.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5DADE2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to RMC',
                style: TextStyle(
                  color: Colors.white,
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
