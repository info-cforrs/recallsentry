import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'add_new_household_item_photo_page.dart';
import '../services/recallmatch_service.dart';
import '../services/recall_data_service.dart';
import '../services/product_scan_service.dart';
import '../services/subscription_service.dart';
import '../models/user_home.dart';
import '../models/user_room.dart';
import '../models/product_scan_result.dart';
import '../models/recall_data.dart';
import 'quick_check_results_page.dart';
import 'verify_recall_results_page.dart';

class AddNewHouseholdItemDetailsPage extends StatefulWidget {
  final Map<PhotoType, XFile?> photos;
  final CompleteScanResult? scanResult;
  final bool isQuickCheckMode;
  final SubscriptionTier? quickCheckTier;
  final bool isVerifyRecallMode;

  const AddNewHouseholdItemDetailsPage({
    super.key,
    required this.photos,
    this.scanResult,
    this.isQuickCheckMode = false,
    this.quickCheckTier,
    this.isVerifyRecallMode = false,
  });

  @override
  State<AddNewHouseholdItemDetailsPage> createState() =>
      _AddNewHouseholdItemDetailsPageState();
}

class _AddNewHouseholdItemDetailsPageState
    extends State<AddNewHouseholdItemDetailsPage> {
  final RecallMatchService _recallMatchService = RecallMatchService();
  final RecallDataService _recallDataService = RecallDataService();
  final ScrollController _scrollController = ScrollController();

  // Form controllers
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final TextEditingController _upcController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _batchLotCodeController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();

  // Dropdown values
  String? _selectedDateType;
  String? _selectedMonth;
  int? _selectedDay;
  int? _selectedYear;
  String? _selectedRetailer;

  // Home and Room selection
  List<UserHome> _userHomes = [];
  List<UserRoom> _userRooms = [];
  UserHome? _selectedHome;
  UserRoom? _selectedRoom;
  bool _isLoadingHomes = false;
  bool _isLoadingRooms = false;
  bool _isSaving = false;
  bool _isQuickChecking = false;

  // Date type options (display names that convert to backend format)
  // Display: "BEST IF USED BY" -> Backend: "BEST_IF_USED_BY"
  final List<String> _dateTypes = [
    'PRODUCTION DATE',
    'EXPIRATION DATE',
    'BEST IF USED BY',
    'SELL BY',
    'MANUFACTURE DATE',
  ];

  // Retailer options
  final List<String> _retailers = [
    'AMAZON',
    'WALMART',
    'TARGET',
    'SAMS CLUB',
    'COSTCO',
    'BEST BUY',
    'KROGER',
    'PUBLIX',
    'OTHER',
  ];

  // Month options
  final List<String> _months = [
    '01-JAN', '02-FEB', '03-MAR', '04-APR', '05-MAY', '06-JUN',
    '07-JUL', '08-AUG', '09-SEP', '10-OCT', '11-NOV', '12-DEC',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserHomes();
    // Initialize year to current year
    _selectedYear = DateTime.now().year;
    // Populate form fields from scan results if available
    _populateFromScanResults();
  }

  /// Populate form fields from scan results
  void _populateFromScanResults() {
    final scanResult = widget.scanResult;
    if (scanResult == null) return;

    // Get form field values from scan result
    final formFields = scanResult.toFormFields();

    // Populate text controllers
    if (formFields['brandName'] != null) {
      _brandNameController.text = formFields['brandName']!;
    }
    if (formFields['productName'] != null) {
      _productNameController.text = formFields['productName']!;
    }
    if (formFields['upc'] != null) {
      _upcController.text = formFields['upc']!;
    }
    if (formFields['modelNumber'] != null) {
      _modelNumberController.text = formFields['modelNumber']!;
    }
    if (formFields['serialNumber'] != null) {
      _serialNumberController.text = formFields['serialNumber']!;
    }
    if (formFields['batchLotCode'] != null) {
      _batchLotCodeController.text = formFields['batchLotCode']!;
    }

    // Set date type and parse date value if found
    if (formFields['dateType'] != null) {
      final dateTypeMap = {
        'EXPIRATION_DATE': 'EXPIRATION DATE',
        'BEST_IF_USED_BY_DATE': 'BEST IF USED BY',
        'SELL_BY_OR_SOLD_BY_DATE': 'SELL BY',
        'PRODUCTION_DATE': 'PRODUCTION DATE',
        'MANUFACTURE_DATE': 'MANUFACTURE DATE',
      };
      _selectedDateType = dateTypeMap[formFields['dateType']] ?? formFields['dateType'];

      // Get the corresponding date value based on date type
      String? dateValue;
      switch (formFields['dateType']) {
        case 'EXPIRATION_DATE':
          dateValue = formFields['expirationDate'];
          break;
        case 'BEST_IF_USED_BY_DATE':
          dateValue = formFields['bestByDate'];
          break;
        case 'SELL_BY_OR_SOLD_BY_DATE':
          dateValue = formFields['sellByDate'];
          break;
        case 'PRODUCTION_DATE':
          dateValue = formFields['productionDate'];
          break;
      }

      // Parse and populate date components
      if (dateValue != null) {
        _parseDateString(dateValue);
      }
    }
  }

  /// Parse a date string and populate month/day/year dropdowns
  /// Supports formats: MM/DD/YYYY, MM-DD-YYYY, MMM DD YYYY, MMM DD, YYYY
  void _parseDateString(String dateStr) {
    final monthNames = {
      'JAN': '01-JAN', 'FEB': '02-FEB', 'MAR': '03-MAR', 'APR': '04-APR',
      'MAY': '05-MAY', 'JUN': '06-JUN', 'JUL': '07-JUL', 'AUG': '08-AUG',
      'SEP': '09-SEP', 'OCT': '10-OCT', 'NOV': '11-NOV', 'DEC': '12-DEC',
    };

    // Try MM/DD/YYYY or MM-DD-YYYY format
    final numericPattern = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})');
    final numericMatch = numericPattern.firstMatch(dateStr);
    if (numericMatch != null) {
      final part1 = int.tryParse(numericMatch.group(1)!);
      final part2 = int.tryParse(numericMatch.group(2)!);
      var year = int.tryParse(numericMatch.group(3)!);

      if (part1 != null && part2 != null && year != null) {
        // Handle 2-digit year
        if (year < 100) {
          year = year + 2000;
        }

        // Determine if MM/DD or DD/MM (assume MM/DD for US dates)
        int month, day;
        if (part1 > 12) {
          // Must be DD/MM format
          day = part1;
          month = part2;
        } else if (part2 > 12) {
          // Must be MM/DD format
          month = part1;
          day = part2;
        } else {
          // Assume MM/DD (US format)
          month = part1;
          day = part2;
        }

        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          _selectedMonth = _months[month - 1];
          _selectedDay = day;
          _selectedYear = year;
        }
      }
      return;
    }

    // Try MMM DD, YYYY or MMM DD YYYY format
    final textPattern = RegExp(r'([A-Z]{3})\s*(\d{1,2}),?\s*(\d{2,4})', caseSensitive: false);
    final textMatch = textPattern.firstMatch(dateStr);
    if (textMatch != null) {
      final monthStr = textMatch.group(1)!.toUpperCase();
      final day = int.tryParse(textMatch.group(2)!);
      var year = int.tryParse(textMatch.group(3)!);

      if (monthNames.containsKey(monthStr) && day != null && year != null) {
        // Handle 2-digit year
        if (year < 100) {
          year = year + 2000;
        }

        if (day >= 1 && day <= 31) {
          _selectedMonth = monthNames[monthStr];
          _selectedDay = day;
          _selectedYear = year;
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _brandNameController.dispose();
    _productNameController.dispose();
    _modelNumberController.dispose();
    _upcController.dispose();
    _productCodeController.dispose();
    _batchLotCodeController.dispose();
    _serialNumberController.dispose();
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userHomes = [];
          _isLoadingHomes = false;
        });
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userRooms = [];
          _isLoadingRooms = false;
        });
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
      print('Error converting photos to base64: $e');
    }

    return photoData;
  }

  Future<void> _addNewItem() async {
    // Validate required fields
    if (_brandNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brand Name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_productNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product or Item Name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedHome == null || _selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a home and room'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Construct item date if all date components are selected
      DateTime? itemDate;
      if (_selectedMonth != null && _selectedDay != null && _selectedYear != null) {
        // Extract numeric month from format "07-JUL" -> "07"
        final monthNum = int.parse(_selectedMonth!.split('-')[0]);
        itemDate = DateTime(
          _selectedYear!,
          monthNum,
          _selectedDay!,
        );
      }

      // Convert photos to base64 format
      final photoData = await _convertPhotosToBase64();

      // Convert date type from display format to backend format
      // "MANUFACTURE DATE" -> "MANUFACTURE_DATE"
      String? backendDateType;
      if (_selectedDateType != null) {
        backendDateType = _selectedDateType!.replaceAll(' ', '_');
      }

      // Create the user item via RecallMatch service
      final createdItem = await _recallMatchService.createUserItem(
        homeId: _selectedHome!.id,
        roomId: _selectedRoom!.id,
        manufacturer: '', // Not collected for household items
        brandName: _brandNameController.text.trim(),
        productName: _productNameController.text.trim(),
        modelNumber: _modelNumberController.text.trim(),
        upc: _upcController.text.trim(),
        sku: _productCodeController.text.trim(), // Product Code
        batchLotCode: _batchLotCodeController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        dateType: backendDateType,
        itemDate: itemDate,
        retailer: _selectedRetailer,
        photoUrls: photoData,
      );

      if (!mounted) return;

      // If in verify recall mode, navigate to results page to check for recalls
      if (widget.isVerifyRecallMode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerifyRecallResultsPage(
              createdItem: createdItem,
              itemType: 'household',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding item: $e'),
          backgroundColor: Colors.red,
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

  /// Perform Quick Check - match item against recalls without saving
  Future<void> _performQuickCheck() async {
    // Validate at least one field has data
    if (_brandNameController.text.trim().isEmpty &&
        _productNameController.text.trim().isEmpty &&
        _modelNumberController.text.trim().isEmpty &&
        _upcController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a brand name or product name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isQuickChecking = true;
    });

    try {
      // Fetch recalls from FDA and CPSC (most likely to contain household items)
      final results = await Future.wait([
        _recallDataService.getFdaRecalls(),
        _recallDataService.getCpscRecalls(),
      ]);

      final fdaRecalls = results[0];
      final cpscRecalls = results[1];
      final allRecalls = [...fdaRecalls, ...cpscRecalls];

      // Perform matching
      final matches = _findMatches(allRecalls);

      if (!mounted) return;

      // Navigate to results page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuickCheckResultsPage(
            tier: widget.quickCheckTier ?? SubscriptionTier.smartFiltering,
            itemType: 'household',
            itemDetails: {
              'brand_name': _brandNameController.text.trim(),
              'product_name': _productNameController.text.trim(),
              'model_number': _modelNumberController.text.trim(),
              'upc': _upcController.text.trim(),
              'batch_lot_code': _batchLotCodeController.text.trim(),
            },
            matchingRecalls: matches,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking recalls: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isQuickChecking = false;
        });
      }
    }
  }

  /// Find matching recalls based on item details
  List<Map<String, dynamic>> _findMatches(List<RecallData> recalls) {
    final matches = <Map<String, dynamic>>[];

    final brandName = _brandNameController.text.trim().toLowerCase();
    final productName = _productNameController.text.trim().toLowerCase();
    final modelNumber = _modelNumberController.text.trim().toLowerCase();
    final upc = _upcController.text.trim();
    final batchLotCode = _batchLotCodeController.text.trim().toLowerCase();

    for (final recall in recalls) {
      double score = 0;
      final matchReasons = <String>[];

      // UPC match (highest priority - exact match)
      final recallUpc = recall.upc;
      if (upc.isNotEmpty && recallUpc.isNotEmpty) {
        if (recallUpc == upc) {
          score += 50;
          matchReasons.add('UPC match');
        }
      }

      // Model number match
      if (modelNumber.isNotEmpty) {
        final recallModel = recall.cpscModel;
        if (recallModel.isNotEmpty) {
          if (recallModel.toLowerCase().contains(modelNumber)) {
            score += 30;
            matchReasons.add('Model match');
          }
        }
      }

      // Brand name match
      if (brandName.isNotEmpty) {
        final recallBrand = recall.brandName.toLowerCase();
        if (recallBrand.contains(brandName) || brandName.contains(recallBrand)) {
          score += 20;
          matchReasons.add('Brand match');
        }
      }

      // Product name match
      if (productName.isNotEmpty) {
        final recallProduct = recall.productName.toLowerCase();
        final productWords = productName.split(' ').where((w) => w.length > 2).toList();
        final recallWords = recallProduct.split(' ').where((w) => w.length > 2).toList();

        int matchingWords = 0;
        for (final word in productWords) {
          if (recallWords.any((rw) => rw.contains(word) || word.contains(rw))) {
            matchingWords++;
          }
        }

        if (matchingWords > 0) {
          score += 10 * matchingWords;
          matchReasons.add('Product name match');
        }
      }

      // Batch/Lot code match
      final recallBatch = recall.batchLotCode;
      if (batchLotCode.isNotEmpty && recallBatch.isNotEmpty) {
        final recallBatchLower = recallBatch.toLowerCase();
        if (recallBatchLower.contains(batchLotCode) || batchLotCode.contains(recallBatchLower)) {
          score += 25;
          matchReasons.add('Lot code match');
        }
      }

      // Only include if score is above threshold
      if (score > 70) {
        matches.add({
          'recall': recall,
          'score': score.clamp(0, 100),
          'reasons': matchReasons,
        });
      }
    }

    // Sort by score descending
    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return matches;
  }

  /// Build the Quick Check section (replaces Home/Room assignment in Quick Check mode)
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
                    child: Text(
                      'Ready to Check for Recalls',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll search our database for any recalls matching your item details.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Quick Check Button
        Center(
          child: SizedBox(
            width: 300,
            height: 56,
            child: ElevatedButton(
              onPressed: _isQuickChecking ? null : _performQuickCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: _isQuickChecking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                            Icons.search,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Quick Check',
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
          widget.isQuickCheckMode
              ? 'Quick Check - Household'
              : widget.isVerifyRecallMode
                  ? 'Verify Item'
                  : 'Add New Household Item',
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
              // PART 1: ITEM PHOTOS
              _buildSection(
                '1). ITEM PHOTOS',
                _buildPhotoCarousel(),
              ),

              const SizedBox(height: 24),

              // PART 2: ITEM INFO
              _buildSection(
                '2). ITEM INFO',
                _buildItemInfoForm(),
              ),

              const SizedBox(height: 40),

              // PART 3: Either Quick Check or Assign Item to Room
              if (widget.isQuickCheckMode && !widget.isVerifyRecallMode) ...[
                _buildSection(
                  '3). QUICK CHECK',
                  _buildQuickCheckSection(),
                ),
              ] else ...[
                _buildSection(
                  '3). ASSIGN ITEM TO ROOM',
                  _buildRoomAssignment(),
                ),

                const SizedBox(height: 32),

                // Add New Item Button
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _addNewItem,
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
                                child: Icon(
                                  widget.isVerifyRecallMode ? Icons.search : Icons.add,
                                  color: const Color(0xFF4CAF50),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.isVerifyRecallMode ? 'Check for Recalls' : 'Add New Item',
                                style: const TextStyle(
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
      PhotoType.front: 'FRONT\n(PIC1)',
      PhotoType.label: 'UPC\n(PIC2)',
      PhotoType.expiration: 'EXP DATE\n(PIC3)',
      PhotoType.back: 'BACK\n(PIC4)',
      PhotoType.top: 'TOP\n(PIC5)',
      PhotoType.bottom: 'BOTTOM\n(PIC6)',
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
                        label.replaceAll('\n', ' '),
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

  Widget _buildItemInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOTE: If you don\'t know all product info, put in as much as you can and we\'ll alert you on only those recalled Products or Models.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField('BRAND NAME:', _brandNameController, '[USER_Brand_Name]', isRequired: true),
        const SizedBox(height: 12),
        _buildTextField('PRODUCT OR\nITEM NAME:', _productNameController, '[USER_Product_Name]', isRequired: true),
        const SizedBox(height: 12),
        _buildTextField('MODEL NUMBER:', _modelNumberController, '[USER_MODEL]'),
        const SizedBox(height: 12),
        _buildTextField('UPC:', _upcController, '[USER_UPC]'),
        const SizedBox(height: 12),
        _buildTextField('PRODUCT CODE:', _productCodeController, '[USER_PRODUCT_CODE]'),
        const SizedBox(height: 12),
        _buildTextField('BATCH or LOT CODE:', _batchLotCodeController, '[USER_BATCH-LOT_CODE]'),
        const SizedBox(height: 12),
        _buildTextField('SERIAL NUMBER:', _serialNumberController, '[USER_SN]'),
        const SizedBox(height: 16),
        _buildDateSection(),
        const SizedBox(height: 16),
        _buildRetailerDropdown(),
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

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Type Dropdown
        const Text(
          'ITEM DATE TYPE:',
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
              value: _selectedDateType,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose Date Type',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
              isExpanded: true,
              dropdownColor: AppColors.tertiary,
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(8),
              selectedItemBuilder: (BuildContext context) {
                return _dateTypes.map<Widget>((String type) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      type,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  );
                }).toList();
              },
              items: _dateTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDateType = newValue;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The date you purchased the item should be entered in the Sold By Date field.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        // Date Components Row
        Row(
          children: [
            // Month
            Expanded(
              flex: 4,
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
                        value: _selectedMonth,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Month',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
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
                          return _months.map<Widget>((String month) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                month,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            );
                          }).toList();
                        },
                        items: _months.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMonth = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Day
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAY',
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
                      child: DropdownButton<int>(
                        value: _selectedDay,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Day',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
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
                          return List.generate(31, (index) => index + 1).map<Widget>((int day) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                day.toString().padLeft(2, '0'),
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            );
                          }).toList();
                        },
                        items: List.generate(31, (index) => index + 1)
                            .map((int day) {
                          return DropdownMenuItem<int>(
                            value: day,
                            child: Text(
                              day.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedDay = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Year
            Expanded(
              flex: 3,
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
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Year',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
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
                          return List.generate(10, (index) {
                            final year = DateTime.now().year - 5 + index;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                year.toString(),
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            );
                          }).toList();
                        },
                        items: List.generate(10, (index) {
                          final year = DateTime.now().year - 5 + index;
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedYear = newValue;
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

  Widget _buildRetailerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WHERE PURCHASED:',
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
              value: _selectedRetailer,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose Retailer',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
              isExpanded: true,
              dropdownColor: AppColors.tertiary,
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(8),
              selectedItemBuilder: (BuildContext context) {
                return _retailers.map<Widget>((String retailer) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      retailer,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  );
                }).toList();
              },
              items: _retailers.map((String retailer) {
                return DropdownMenuItem<String>(
                  value: retailer,
                  child: Text(retailer, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRetailer = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomAssignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add New Item Where?',
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

        // B). SELECT ROOM
        const Text(
          'B). SELECT ROOM',
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
          const Text(
            'No rooms available for this home. Please add a room first.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _userRooms.map((room) {
              final isSelected = _selectedRoom?.id == room.id;
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
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    room.name,
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

        if (_selectedHome != null && _selectedRoom != null) ...[
          const SizedBox(height: 20),
          Text(
            'Item goes to: ${_selectedHome!.name} -> ${_selectedRoom!.name}',
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
