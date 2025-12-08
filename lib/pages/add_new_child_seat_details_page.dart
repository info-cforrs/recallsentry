import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'add_new_child_seat_photo_page.dart';
import '../services/recallmatch_service.dart';
import '../services/recall_data_service.dart';
import '../services/subscription_service.dart';
import '../models/user_home.dart';
import '../models/user_room.dart';
import '../models/recall_data.dart';
import '../models/product_scan_result.dart';
import 'quick_check_results_page.dart';
import 'verify_recall_results_page.dart';

class AddNewChildSeatDetailsPage extends StatefulWidget {
  final Map<ChildSeatPhotoType, XFile?> photos;
  final String? scannedUpc;
  final LabelScanResult? labelScanResult;
  final bool isQuickCheckMode;
  final SubscriptionTier? quickCheckTier;
  final bool isVerifyRecallMode;

  const AddNewChildSeatDetailsPage({
    super.key,
    required this.photos,
    this.scannedUpc,
    this.labelScanResult,
    this.isQuickCheckMode = false,
    this.quickCheckTier,
    this.isVerifyRecallMode = false,
  });

  @override
  State<AddNewChildSeatDetailsPage> createState() =>
      _AddNewChildSeatDetailsPageState();
}

class _AddNewChildSeatDetailsPageState extends State<AddNewChildSeatDetailsPage> {
  final RecallMatchService _recallMatchService = RecallMatchService();
  final RecallDataService _recallDataService = RecallDataService();
  final ScrollController _scrollController = ScrollController();

  // Form controllers
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final TextEditingController _upcController = TextEditingController();
  final TextEditingController _retailerController = TextEditingController();

  // Production date dropdowns
  String? _selectedProductionMonth;
  String? _selectedProductionYear;

  // Home and Room selection
  List<UserHome> _userHomes = [];
  List<UserRoom> _userRooms = [];
  UserHome? _selectedHome;
  UserRoom? _selectedRoom;
  bool _isLoadingHomes = false;
  bool _isLoadingRooms = false;
  bool _isSaving = false;
  bool _isQuickChecking = false;

  @override
  void initState() {
    super.initState();
    _loadUserHomes();
    _populateFromScanResults();
  }

  void _populateFromScanResults() {
    // Populate UPC if scanned
    if (widget.scannedUpc != null && widget.scannedUpc!.isNotEmpty) {
      _upcController.text = widget.scannedUpc!;
    }

    // Populate from label OCR if available
    if (widget.labelScanResult != null && widget.labelScanResult!.success) {
      for (final field in widget.labelScanResult!.extractedFields) {
        switch (field.fieldType) {
          case LabelFieldType.brandName:
          case LabelFieldType.manufacturer:
            if (_manufacturerController.text.isEmpty) {
              _manufacturerController.text = field.value;
            }
            break;
          case LabelFieldType.productName:
            if (_modelController.text.isEmpty) {
              _modelController.text = field.value;
            }
            break;
          case LabelFieldType.modelNumber:
            if (_modelNumberController.text.isEmpty) {
              _modelNumberController.text = field.value;
            }
            break;
          case LabelFieldType.upc:
            if (_upcController.text.isEmpty) {
              _upcController.text = field.value;
            }
            break;
          default:
            break;
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _modelNumberController.dispose();
    _upcController.dispose();
    _retailerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserHomes() async {
    setState(() {
      _isLoadingHomes = true;
    });

    try {
      final homes = await _recallMatchService.getUserHomes();
      if (mounted) {
        setState(() {
          _userHomes = homes;
          _isLoadingHomes = false;
        });

        // Auto-select first home if only one exists
        if (homes.length == 1) {
          _onHomeSelected(homes.first);
        }
      }
    } catch (e) {
      debugPrint('Error loading homes: $e');
      if (mounted) {
        setState(() {
          _userHomes = [];
          _isLoadingHomes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading homes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRoomsForHome(int homeId) async {
    setState(() {
      _isLoadingRooms = true;
      _userRooms = [];
      _selectedRoom = null;
    });

    try {
      final rooms = await _recallMatchService.getRoomsByHome(homeId);
      if (mounted) {
        setState(() {
          _userRooms = rooms;
          _isLoadingRooms = false;
          // Auto-select Garage if it exists
          for (final room in rooms) {
            if (room.roomType == 'garage' || room.name.toLowerCase().contains('garage')) {
              _selectedRoom = room;
              break;
            }
          }
          // If no garage found but rooms exist, select the first one
          if (_selectedRoom == null && rooms.isNotEmpty) {
            _selectedRoom = rooms.first;
          }
        });

        // Show message if no garage found
        if (_selectedRoom != null && !(_selectedRoom!.roomType == 'garage' || _selectedRoom!.name.toLowerCase().contains('garage'))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No Garage found. Selected first available room.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading rooms: $e');
      if (mounted) {
        setState(() {
          _userRooms = [];
          _isLoadingRooms = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rooms: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onHomeSelected(UserHome home) {
    setState(() {
      _selectedHome = home;
      _selectedRoom = null;
    });
    _loadRoomsForHome(home.id);
  }

  void _onRoomSelected(UserRoom room) {
    setState(() {
      _selectedRoom = room;
    });
  }

  Future<List<String>> _convertPhotosToBase64() async {
    final List<String> photoData = [];

    try {
      for (final entry in widget.photos.entries) {
        if (entry.value != null) {
          final file = File(entry.value!.path);
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);

          // Format: "data:image/jpeg;base64,{base64String}"
          photoData.add('data:image/jpeg;base64,$base64String');
        }
      }
    } catch (e) {
      debugPrint('Error converting photos to base64: $e');
    }

    return photoData;
  }

  Future<void> _addNewChildSeat() async {
    // Validate required fields - Manufacturer and Model are required
    final List<String> missingFields = [];
    if (_manufacturerController.text.trim().isEmpty) {
      missingFields.add('Manufacturer/Make');
    }
    if (_modelController.text.trim().isEmpty) {
      missingFields.add('Model');
    }

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter required fields: ${missingFields.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedHome == null || _selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a home and room (Garage)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert photos to base64 format
      final photoData = await _convertPhotosToBase64();

      // Create the child seat item via RecallMatch service
      // For child seats, use manufacturer and modelNumber fields (not brandName/productName)
      final createdItem = await _recallMatchService.createUserItem(
        homeId: _selectedHome!.id,
        roomId: _selectedRoom!.id,
        manufacturer: _manufacturerController.text.trim(),
        brandName: '', // Leave empty for child seats - use manufacturer instead
        productName: '', // Leave empty for child seats
        modelNumber: _modelController.text.trim(), // Store model name here
        upc: _upcController.text.trim().isNotEmpty ? _upcController.text.trim() : null,
        retailer: _retailerController.text.trim().isNotEmpty ? _retailerController.text.trim() : null,
        photoUrls: photoData,
        // Child seat-specific fields
        itemCategory: 'child_seat',
        childSeatModelNumber: _modelNumberController.text.trim().isNotEmpty ? _modelNumberController.text.trim() : null,
        childSeatProductionMonth: _selectedProductionMonth,
        childSeatProductionYear: _selectedProductionYear,
      );

      if (!mounted) return;

      // If in verify recall mode, navigate to results page to check for recalls
      if (widget.isVerifyRecallMode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerifyRecallResultsPage(
              createdItem: createdItem,
              itemType: 'child_seat',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Child seat added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop back through the navigation stack
      Navigator.of(context).pop(); // Pop details page
      Navigator.of(context).pop(); // Pop photo page
    } catch (e) {
      debugPrint('Error adding child seat: $e');
      if (!mounted) return;

      String errorMessage = 'Error adding child seat';
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Session expired. Please log in again.';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Invalid data. Please check all fields.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Perform Quick Check - match child seat against NHTSA recalls
  Future<void> _performQuickCheck() async {
    if (_manufacturerController.text.trim().isEmpty &&
        _modelController.text.trim().isEmpty &&
        _modelNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a manufacturer or model'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isQuickChecking = true;
    });

    try {
      final recalls = await _recallDataService.getNhtsaChildSeatRecalls();
      final matches = _findMatches(recalls);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuickCheckResultsPage(
            tier: widget.quickCheckTier ?? SubscriptionTier.smartFiltering,
            itemType: 'child_seat',
            itemDetails: {
              'manufacturer': _manufacturerController.text.trim(),
              'model': _modelController.text.trim(),
              'model_number': _modelNumberController.text.trim(),
              'upc': _upcController.text.trim(),
            },
            matchingRecalls: matches,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking recalls: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isQuickChecking = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _findMatches(List<RecallData> recalls) {
    final matches = <Map<String, dynamic>>[];
    final manufacturer = _manufacturerController.text.trim().toLowerCase();
    final model = _modelController.text.trim().toLowerCase();
    final modelNumber = _modelNumberController.text.trim().toLowerCase();
    final upc = _upcController.text.trim();

    for (final recall in recalls) {
      double score = 0;
      final matchReasons = <String>[];

      // Check UPC match (highest priority)
      if (upc.isNotEmpty) {
        final recallUpc = recall.nhtsaUpc;
        if (recallUpc.isNotEmpty && recallUpc == upc) {
          score += 50;
          matchReasons.add('UPC match');
        }
      }

      // Check manufacturer match
      if (manufacturer.isNotEmpty) {
        final recallMfr = recall.brandName.isNotEmpty
            ? recall.brandName.toLowerCase()
            : recall.nhtsaVehicleMake.toLowerCase();
        if (recallMfr.contains(manufacturer) || manufacturer.contains(recallMfr)) {
          score += 30;
          matchReasons.add('Manufacturer match');
        }
      }

      // Check model match
      if (model.isNotEmpty) {
        final recallModel = recall.nhtsaModelNum.toLowerCase();
        final recallProduct = recall.productName.toLowerCase();
        if (recallModel.contains(model) || model.contains(recallModel) ||
            recallProduct.contains(model) || model.contains(recallProduct)) {
          score += 25;
          matchReasons.add('Model match');
        }
      }

      // Check model number match
      if (modelNumber.isNotEmpty) {
        final recallModelNum = recall.nhtsaModelNum.toLowerCase();
        if (recallModelNum.contains(modelNumber) || modelNumber.contains(recallModelNum)) {
          score += 25;
          matchReasons.add('Model number match');
        }
      }

      if (score > 70) {
        matches.add({'recall': recall, 'score': score.clamp(0, 100), 'reasons': matchReasons});
      }
    }

    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return matches;
  }

  Widget _buildQuickCheckSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF4CAF50), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Ready to Check for Recalls',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('We\'ll search NHTSA\'s database for any child seat recalls matching your information.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 300,
            height: 56,
            child: ElevatedButton(
              onPressed: _isQuickChecking ? null : _performQuickCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isQuickChecking
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.search, color: Color(0xFF4CAF50), size: 20)),
                      const SizedBox(width: 12),
                      const Text('Quick Check', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ]),
            ),
          ),
        ),
      ],
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isQuickCheckMode ? 'Quick Check - Child Seat' : 'Add New Child Seat',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PART 1: CHILD SEAT PHOTOS
              _buildSection(
                '1). CHILD SEAT PHOTOS',
                _buildPhotoCarousel(),
              ),

              const SizedBox(height: 24),

              // PART 2: CHILD SEAT INFO
              _buildSection(
                '2). CHILD SEAT INFO',
                _buildChildSeatInfoForm(),
              ),

              const SizedBox(height: 40),

              // PART 3: Conditional based on Quick Check mode
              if (widget.isQuickCheckMode) ...[
                _buildSection(
                  '3). QUICK CHECK',
                  _buildQuickCheckSection(),
                ),
                const SizedBox(height: 32),
              ] else ...[
                // PART 3: ASSIGN CHILD SEAT TO GARAGE
                _buildSection(
                  '3). ASSIGN CHILD SEAT TO GARAGE',
                  _buildGarageAssignment(),
                ),

                const SizedBox(height: 32),

                // Add New Child Seat Button
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _addNewChildSeat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Color(0xFF4CAF50),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Add New Child Seat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ], // End of else block
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildPhotoCarousel() {
    // Get all photos that were actually captured
    final capturedPhotos = widget.photos.entries
        .where((entry) => entry.value != null)
        .toList();

    // Map photo types to display labels
    final photoLabels = {
      ChildSeatPhotoType.seatLabel: 'SEAT LABEL',
      ChildSeatPhotoType.frontView: 'FRONT VIEW',
      ChildSeatPhotoType.sideView: 'SIDE VIEW',
      ChildSeatPhotoType.backView: 'BACK VIEW',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5A6C7D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: capturedPhotos.length,
          itemBuilder: (context, index) {
            final photoEntry = capturedPhotos[index];
            final photoType = photoEntry.key;
            final photo = photoEntry.value!;
            final label = photoLabels[photoType] ?? 'PHOTO ${index + 1}';

            return Padding(
              padding: EdgeInsets.only(right: index < capturedPhotos.length - 1 ? 12 : 0),
              child: Stack(
                children: [
                  // Photo display
                  Container(
                    width: 120,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Label overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChildSeatInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('MANUFACTURER/\nMAKE:', _manufacturerController, 'e.g., Chicco, Graco, Britax', isRequired: true),
        const SizedBox(height: 12),
        _buildTextField('MODEL:', _modelController, 'e.g., KeyFit 30, 4Ever, Marathon', isRequired: true),
        const SizedBox(height: 12),
        _buildTextField('MODEL NUMBER:', _modelNumberController, 'From seat info label (optional)'),
        const SizedBox(height: 12),

        // Production Date dropdowns (Month and Year)
        _buildProductionDateRow(),
        const SizedBox(height: 12),

        _buildTextField('UPC:', _upcController, 'Universal Product Code (optional)'),
        const SizedBox(height: 12),
        _buildTextField('WHERE PURCHASED:', _retailerController, 'e.g., Target, Buy Buy Baby, Amazon'),

        const SizedBox(height: 16),

        // Note about partial info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.lightbulb_outline, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NOTE: If you don\'t know all product info, put in as much as you can and we\'ll alert you on only those recalled Manufacturers, Products or Models.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Production Date row with Month and Year dropdowns
  Widget _buildProductionDateRow() {
    // Generate month options (01-12)
    final monthOptions = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));

    // Generate year options (2000-2030)
    final yearOptions = List.generate(31, (i) => (2000 + i).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRODUCTION DATE:',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Month dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MONTH',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProductionMonth,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Month', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                        isExpanded: true,
                        dropdownColor: AppColors.tertiary,
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        borderRadius: BorderRadius.circular(8),
                        selectedItemBuilder: (BuildContext context) {
                          return [null, ...monthOptions].map<Widget>((String? month) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                month != null ? 'Mo $month' : '',
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            );
                          }).toList();
                        },
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Month', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ),
                          ...monthOptions.map((String month) {
                            return DropdownMenuItem<String>(
                              value: month,
                              child: Text('Month $month', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            );
                          }),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedProductionMonth = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Year dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YEAR',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProductionYear,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Year', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                        isExpanded: true,
                        dropdownColor: AppColors.tertiary,
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        borderRadius: BorderRadius.circular(8),
                        selectedItemBuilder: (BuildContext context) {
                          return [null, ...yearOptions].map<Widget>((String? year) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                year ?? '',
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            );
                          }).toList();
                        },
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Year', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ),
                          ...yearOptions.map((String year) {
                            return DropdownMenuItem<String>(
                              value: year,
                              child: Text(year, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            );
                          }),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedProductionYear = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isRequired = false, TextInputType keyboardType = TextInputType.text}) {
    // Remove newlines from label and format nicely
    final cleanLabel = label.replaceAll('\n', ' ').trim();
    final displayLabel = isRequired ? '$cleanLabel *' : cleanLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.tertiary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.secondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.secondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.accentBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGarageAssignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Child Seat Where?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // A). SELECT HOME
        const Text(
          'A). SELECT HOME',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (_isLoadingHomes)
          const Center(child: CircularProgressIndicator())
        else if (_userHomes.isEmpty)
          const Text(
            'No homes available. Please add a home first.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _userHomes.map((home) {
              final isSelected = _selectedHome?.id == home.id;
              return GestureDetector(
                onTap: () => _onHomeSelected(home),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2C5F7C)
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF64B5F6)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    home.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 20),

        // B). SELECT GARAGE
        const Text(
          'B). SELECT GARAGE',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (_selectedHome == null)
          const Text(
            'Please select a home first',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          )
        else if (_isLoadingRooms)
          const Center(child: CircularProgressIndicator())
        else if (_userRooms.isEmpty)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No rooms available. Please add a Garage first.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _userRooms.map((room) {
              final isSelected = _selectedRoom?.id == room.id;
              final isGarage = room.roomType == 'garage' || room.name.toLowerCase().contains('garage');
              return GestureDetector(
                onTap: () => _onRoomSelected(room),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2C5F7C)
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF64B5F6)
                          : isGarage
                              ? Colors.orange.withValues(alpha: 0.5)
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGarage)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.garage, color: Colors.orange, size: 18),
                        ),
                      Text(
                        room.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        if (_selectedHome != null && _selectedRoom != null) ...[
          const SizedBox(height: 20),
          Text(
            'Child seat goes to: ${_selectedHome!.name} -> ${_selectedRoom!.name}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
