import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'add_new_vehicle_photo_page.dart';
import '../services/recallmatch_service.dart';
import '../services/recall_data_service.dart';
import '../services/subscription_service.dart';
import '../models/user_home.dart';
import '../models/user_room.dart';
import '../models/recall_data.dart';
import '../services/vin_decode_service.dart';
import 'quick_check_results_page.dart';
import 'verify_recall_results_page.dart';

class AddNewVehicleDetailsPage extends StatefulWidget {
  final Map<VehiclePhotoType, XFile?> photos;
  final String? scannedVin;
  final bool isQuickCheckMode;
  final SubscriptionTier? quickCheckTier;
  final bool isVerifyRecallMode;

  const AddNewVehicleDetailsPage({
    super.key,
    required this.photos,
    this.scannedVin,
    this.isQuickCheckMode = false,
    this.quickCheckTier,
    this.isVerifyRecallMode = false,
  });

  @override
  State<AddNewVehicleDetailsPage> createState() =>
      _AddNewVehicleDetailsPageState();
}

class _AddNewVehicleDetailsPageState extends State<AddNewVehicleDetailsPage> {
  final RecallMatchService _recallMatchService = RecallMatchService();
  final RecallDataService _recallDataService = RecallDataService();
  final VinDecodeService _vinDecodeService = VinDecodeService();
  final ScrollController _scrollController = ScrollController();

  // Form controllers
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _trimController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();

  // Dropdown values
  String? _selectedYear;
  String? _selectedMonth;
  int? _selectedProductionYear;

  // Home and Room selection
  List<UserHome> _userHomes = [];
  List<UserRoom> _userRooms = [];
  UserHome? _selectedHome;
  UserRoom? _selectedRoom;
  bool _isLoadingHomes = false;
  bool _isLoadingRooms = false;
  bool _isSaving = false;
  bool _isQuickChecking = false;
  bool _isDecodingVin = false;
  bool _vinDecoded = false;

  // Year options (current year back to 1990)
  List<String> get _years {
    final currentYear = DateTime.now().year + 1; // Include next model year
    return List.generate(currentYear - 1990 + 1, (index) => (currentYear - index).toString());
  }

  // Month options for production date
  final List<String> _months = [
    '01-JAN', '02-FEB', '03-MAR', '04-APR', '05-MAY', '06-JUN',
    '07-JUL', '08-AUG', '09-SEP', '10-OCT', '11-NOV', '12-DEC',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserHomes();
    // Initialize production year to current year
    _selectedProductionYear = DateTime.now().year;
    // Pre-fill VIN if scanned and auto-decode
    if (widget.scannedVin != null && widget.scannedVin!.isNotEmpty) {
      _vinController.text = widget.scannedVin!;
      // Auto-decode VIN after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _decodeVin();
      });
    }
  }

  /// Decode VIN and populate vehicle details
  Future<void> _decodeVin() async {
    debugPrint('🔍 _decodeVin called - isQuickCheckMode: ${widget.isQuickCheckMode}');
    final vin = _vinController.text.trim();
    debugPrint('📋 VIN to decode: "$vin" (length: ${vin.length})');

    if (vin.isEmpty) {
      debugPrint('⚠️ VIN is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a VIN to decode'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (vin.length != 17) {
      debugPrint('⚠️ VIN length is not 17: ${vin.length}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VIN must be 17 characters'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDecodingVin = true;
    });

    try {
      debugPrint('🌐 Calling NHTSA API to decode VIN...');
      final result = await _vinDecodeService.decodeVin(vin);
      debugPrint('📊 API result: success=${result.success}, make=${result.make}, model=${result.model}, year=${result.year}');

      if (!mounted) return;

      if (result.success) {
        setState(() {
          // Populate fields from decoded VIN
          if (result.make != null && result.make!.isNotEmpty) {
            _makeController.text = result.make!;
          }
          if (result.model != null && result.model!.isNotEmpty) {
            _modelController.text = result.model!;
          }
          if (result.trim != null && result.trim!.isNotEmpty) {
            _trimController.text = result.trim!;
          }
          if (result.year != null && result.year!.isNotEmpty) {
            // Find matching year in dropdown
            if (_years.contains(result.year)) {
              _selectedYear = result.year;
            }
          }
          _vinDecoded = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VIN decoded: ${result.year ?? ''} ${result.make ?? ''} ${result.model ?? ''}'.trim()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to decode VIN'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error decoding VIN: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDecodingVin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _trimController.dispose();
    _vinController.dispose();
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

  Future<void> _addNewVehicle() async {
    // Validate required fields
    if (_makeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle Make is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_modelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle Model is required'),
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
      // Construct production date if month and year are selected
      DateTime? productionDate;
      if (_selectedMonth != null && _selectedProductionYear != null) {
        final monthNum = int.parse(_selectedMonth!.split('-')[0]);
        productionDate = DateTime(_selectedProductionYear!, monthNum, 1);
      }

      // Convert photos to base64 format
      final photoData = await _convertPhotosToBase64();

      // Build product name from make/model/trim
      String productName = '${_makeController.text.trim()} ${_modelController.text.trim()}';
      if (_trimController.text.trim().isNotEmpty) {
        productName += ' ${_trimController.text.trim()}';
      }

      // Create the vehicle item via RecallMatch service
      final createdItem = await _recallMatchService.createUserItem(
        homeId: _selectedHome!.id,
        roomId: _selectedRoom!.id,
        manufacturer: _makeController.text.trim(), // Use Make as manufacturer
        brandName: _makeController.text.trim(), // Use Make as brand
        productName: productName,
        modelNumber: _modelController.text.trim(),
        dateType: productionDate != null ? 'MANUFACTURE_DATE' : null,
        itemDate: productionDate,
        photoUrls: photoData,
        // Vehicle-specific fields
        itemCategory: 'vehicle',
        vehicleYear: _selectedYear,
        vehicleMake: _makeController.text.trim(),
        vehicleModel: _modelController.text.trim(),
        vehicleVin: _vinController.text.trim().isNotEmpty ? _vinController.text.trim() : null,
      );

      if (!mounted) return;

      // If in verify recall mode, navigate to results page to check for recalls
      if (widget.isVerifyRecallMode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerifyRecallResultsPage(
              createdItem: createdItem,
              itemType: 'vehicle',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop back through the navigation stack (photo page -> home view page)
      // The home view page will call _loadRooms() when we return
      Navigator.of(context).pop(); // Pop details page
      Navigator.of(context).pop(); // Pop photo page
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
      if (!mounted) return;

      String errorMessage = 'Error adding vehicle';
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

  /// Perform Quick Check - match vehicle against NHTSA recalls
  /// If a valid VIN is provided, uses NHTSA's direct VIN recall API for exact matches.
  /// Otherwise, falls back to fuzzy matching by make/model/year.
  Future<void> _performQuickCheck() async {
    final vin = _vinController.text.trim().toUpperCase();
    final hasValidVin = vin.length == 17 && !vin.contains(RegExp(r'[IOQ]'));

    if (!hasValidVin &&
        _makeController.text.trim().isEmpty &&
        _modelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a VIN, or at least a make or model'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isQuickChecking = true;
    });

    try {
      List<Map<String, dynamic>> matches;

      // If valid VIN provided, use NHTSA's direct VIN recall API
      if (hasValidVin) {
        debugPrint('🚗 Using VIN-based NHTSA recall lookup for: $vin');
        final vinResult = await _recallMatchService.getRecallsByVin(vin);

        if (!mounted) return;

        if (vinResult.upgradeRequired) {
          // User needs to upgrade - show message and fall back to fuzzy matching
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vinResult.error ?? 'VIN lookup requires SmartFiltering or RecallMatch subscription'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          // Fall back to fuzzy matching
          final recalls = await _recallDataService.getNhtsaVehicleRecalls();
          matches = _findMatches(recalls);
        } else if (!vinResult.success) {
          // API error - fall back to fuzzy matching
          debugPrint('⚠️ VIN lookup failed: ${vinResult.error}');
          final recalls = await _recallDataService.getNhtsaVehicleRecalls();
          matches = _findMatches(recalls);
        } else {
          // VIN lookup successful - convert VinRecall to match format
          matches = vinResult.recalls.map((vinRecall) {
            // Create a simplified RecallData-like map for the results page
            return {
              'recall': RecallData(
                id: vinRecall.nhtsaCampaignNumber,
                agency: 'NHTSA',
                productName: '${vinRecall.modelYear} ${vinRecall.make} ${vinRecall.model}',
                brandName: vinRecall.manufacturer,
                riskLevel: vinRecall.parkIt ? 'HIGH' : (vinRecall.parkOutside ? 'MEDIUM' : 'LOW'),
                dateIssued: DateTime.tryParse(vinRecall.reportReceivedDate) ?? DateTime.now(),
                description: vinRecall.summary,
                category: 'Vehicle',
                negativeOutcomes: vinRecall.consequence,
                remedy: vinRecall.remedy,
                nhtsaCampaignNumber: vinRecall.nhtsaCampaignNumber,
                nhtsaComponent: vinRecall.component,
                nhtsaRecallType: 'Vehicle',
                nhtsaVehicleMake: vinRecall.make,
                nhtsaVehicleModel: vinRecall.model,
                nhtsaVehicleYearStart: vinRecall.modelYear,
                nhtsaVehicleYearEnd: vinRecall.modelYear,
                nhtsaDoNotDrive: vinRecall.parkIt,
                nhtsaFireRisk: vinRecall.parkOutside,
              ),
              'score': 100.0, // VIN match is exact
              'reasons': ['VIN exact match (${vin.substring(0, 4)}...${vin.substring(13)})'],
            };
          }).toList();

          debugPrint('✅ VIN lookup found ${matches.length} recalls');
        }
      } else {
        // No valid VIN - use fuzzy matching
        debugPrint('🔍 Using fuzzy matching (no valid VIN)');
        final recalls = await _recallDataService.getNhtsaVehicleRecalls();
        matches = _findMatches(recalls);
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuickCheckResultsPage(
            tier: widget.quickCheckTier ?? SubscriptionTier.smartFiltering,
            itemType: 'vehicle',
            itemDetails: {
              'make': _makeController.text.trim(),
              'model': _modelController.text.trim(),
              'year': _selectedYear ?? '',
              'vin': vin,
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
    final make = _makeController.text.trim().toLowerCase();
    final model = _modelController.text.trim().toLowerCase();
    final year = _selectedYear ?? '';

    for (final recall in recalls) {
      double score = 0;
      final matchReasons = <String>[];

      // Check make match
      if (make.isNotEmpty) {
        final recallMake = recall.nhtsaVehicleMake.toLowerCase();
        if (recallMake.contains(make) || make.contains(recallMake)) {
          score += 30;
          matchReasons.add('Make match');
        }
      }

      // Check model match
      if (model.isNotEmpty) {
        final recallModel = recall.nhtsaVehicleModel.toLowerCase();
        if (recallModel.contains(model) || model.contains(recallModel)) {
          score += 30;
          matchReasons.add('Model match');
        }
      }

      // Check year match (within range)
      if (year.isNotEmpty) {
        final yearInt = int.tryParse(year);
        final startYear = int.tryParse(recall.nhtsaVehicleYearStart);
        final endYear = int.tryParse(recall.nhtsaVehicleYearEnd);

        if (yearInt != null) {
          bool yearMatch = false;
          if (startYear != null && endYear != null) {
            yearMatch = yearInt >= startYear && yearInt <= endYear;
          } else if (startYear != null) {
            yearMatch = yearInt == startYear;
          }

          if (yearMatch) {
            score += 25;
            matchReasons.add('Year match');
          }
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
              Text('We\'ll search NHTSA\'s database for any vehicle recalls matching your information.',
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
          widget.isQuickCheckMode ? 'Quick Check - Vehicle' : 'Add New Vehicle',
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
              // PART 1: VEHICLE PHOTOS
              _buildSection(
                '1). VEHICLE PHOTOS',
                _buildPhotoCarousel(),
              ),

              const SizedBox(height: 24),

              // PART 2: VEHICLE INFO
              _buildSection(
                '2). VEHICLE INFO',
                _buildVehicleInfoForm(),
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
                // PART 3: ASSIGN VEHICLE TO GARAGE
                _buildSection(
                  '3). ASSIGN VEHICLE TO GARAGE',
                  _buildGarageAssignment(),
                ),

                const SizedBox(height: 32),

                // Add New Vehicle Button
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _addNewVehicle,
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
                                  'Add New Vehicle',
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
      VehiclePhotoType.front: 'FRONT',
      VehiclePhotoType.back: 'BACK',
      VehiclePhotoType.driverSide: 'DRIVER SIDE',
      VehiclePhotoType.vin: 'VIN',
      VehiclePhotoType.interior: 'INTERIOR',
      VehiclePhotoType.other: 'OTHER',
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

  Widget _buildVehicleInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('MAKE:', _makeController, 'e.g., Chevrolet, Ford, Toyota', isRequired: true),
        const SizedBox(height: 12),
        _buildTextField('MODEL:', _modelController, 'e.g., Silverado, F-150, Camry', isRequired: true),
        const SizedBox(height: 12),
        _buildTextField('TRIM:', _trimController, 'e.g., LT, XLT, SE (optional)'),
        const SizedBox(height: 12),

        // Model Year dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MODEL YEAR:',
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
                  value: _selectedYear,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Select Year',
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
                    return _years.map<Widget>((String year) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          year,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList();
                  },
                  items: _years.map((String year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedYear = newValue;
                    });
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        // VIN field with decode button
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VIN:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vinController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '17-character Vehicle ID Number',
                      hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: AppColors.secondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      suffixIcon: _vinDecoded
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 17,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isDecodingVin ? null : _decodeVin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: _isDecodingVin
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Decode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Production Date section
        _buildProductionDateSection(),

        const SizedBox(height: 12),

        // Note about production date info location
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NOTE: This information is on the driver\'s side door jam or pillar placard for the month of manufacture.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Vehicle add info image
        Center(
          child: Image.asset(
            'assets/images/User_Vehicle_Add_Pic.png',
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Silently fail if image doesn't exist
              return const SizedBox.shrink();
            },
          ),
        ),

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

  Widget _buildProductionDateSection() {
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
            // Month
            Expanded(
              flex: 5,
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
            const SizedBox(width: 16),
            // Year
            Expanded(
              flex: 4,
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
                        value: _selectedProductionYear,
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
                          return List.generate(40, (index) {
                            final year = DateTime.now().year - index;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                year.toString(),
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            );
                          }).toList();
                        },
                        items: List.generate(40, (index) {
                          final year = DateTime.now().year - index;
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

  Widget _buildGarageAssignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Vehicle Where?',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
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
            'Vehicle goes to: ${_selectedHome!.name} -> ${_selectedRoom!.name}',
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
