import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../constants/app_colors.dart';
import '../models/recall_data.dart';
import '../models/user_home.dart';
import '../models/user_room.dart';
import '../services/recallmatch_service.dart';
import '../services/api_service.dart';
import '../services/product_scan_service.dart';
import '../services/vin_decode_service.dart';
import '../services/barcode_scan_service.dart';
import '../models/product_scan_result.dart';
import '../widgets/custom_loading_indicator.dart';
import 'rmc_details_page.dart';

/// Add Item From Recall Page
///
/// Simple flow for adding an item to inventory when user clicks
/// "I Have This Recalled Item" from a recall details page.
/// - Pre-populates form fields from the recall
/// - 2 optional photos (front photo + UPC/label)
/// - Home/Room selection
/// - Auto-enrolls in RMC on save
class AddItemFromRecallPage extends StatefulWidget {
  final RecallData recall;

  const AddItemFromRecallPage({
    super.key,
    required this.recall,
  });

  @override
  State<AddItemFromRecallPage> createState() => _AddItemFromRecallPageState();
}

class _AddItemFromRecallPageState extends State<AddItemFromRecallPage>
    with WidgetsBindingObserver {
  final RecallMatchService _recallMatchService = RecallMatchService();
  final ApiService _apiService = ApiService();
  final ProductScanService _scanService = ProductScanService();
  final VinDecodeService _vinDecodeService = VinDecodeService();
  final BarcodeScanService _barcodeScanService = BarcodeScanService();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // Photos - 2 slots: front and label
  XFile? _frontPhoto;
  XFile? _labelPhoto;
  String? _activePhotoSlot; // 'front' or 'label'

  // Form controllers
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final TextEditingController _upcController = TextEditingController();
  final TextEditingController _batchLotCodeController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();

  // Vehicle-specific state
  bool _isDecodingVin = false;
  bool _vinDecoded = false;

  // Home and Room selection
  List<UserHome> _userHomes = [];
  List<UserRoom> _userRooms = [];
  UserHome? _selectedHome;
  UserRoom? _selectedRoom;
  bool _isLoadingHomes = false;
  bool _isLoadingRooms = false;

  // State
  bool _isSaving = false;
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _populateFromRecall();
    _loadUserHomes();
  }

  /// Check if this recall is for a vehicle (NHTSA agency)
  bool get _isVehicleRecall => widget.recall.agency == 'NHTSA';

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scrollController.dispose();
    _brandNameController.dispose();
    _itemNameController.dispose();
    _modelNumberController.dispose();
    _upcController.dispose();
    _batchLotCodeController.dispose();
    _vinController.dispose();

    // Clean up photo files
    _cleanupPhotoFile(_frontPhoto);
    _cleanupPhotoFile(_labelPhoto);

    super.dispose();
  }

  void _cleanupPhotoFile(XFile? photo) {
    if (photo != null) {
      try {
        final file = File(photo.path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Pre-populate form fields from the recall data
  void _populateFromRecall() {
    _brandNameController.text = widget.recall.brandName;
    _itemNameController.text = widget.recall.productName;

    // For CPSC recalls, use the model number
    if (widget.recall.agency == 'CPSC' && widget.recall.cpscModel.isNotEmpty) {
      _modelNumberController.text = widget.recall.cpscModel;
    }

    // For NHTSA recalls, use model number if available
    if (widget.recall.agency == 'NHTSA' &&
        widget.recall.nhtsaModelNum.isNotEmpty) {
      _modelNumberController.text = widget.recall.nhtsaModelNum;
    }

    // UPC code
    if (widget.recall.upc.isNotEmpty) {
      _upcController.text = widget.recall.upc;
    } else if (widget.recall.nhtsaUpc.isNotEmpty) {
      _upcController.text = widget.recall.nhtsaUpc;
    }

    // Batch/Lot code
    if (widget.recall.batchLotCode.isNotEmpty) {
      _batchLotCodeController.text = widget.recall.batchLotCode;
    }
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

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      await _initializeCamera();
    } else if (status.isDenied) {
      setState(() {
        _errorMessage = 'Camera permission is required to take photos';
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage =
            'Camera permission permanently denied. Please enable it in settings.';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_activePhotoSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a photo slot first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not ready'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();

      // Compress and resize the image
      final File imageFile = File(photo.path);
      final img.Image? originalImage =
          img.decodeImage(await imageFile.readAsBytes());

      if (originalImage != null) {
        final img.Image resizedImage = originalImage.width > 1200
            ? img.copyResize(originalImage, width: 1200)
            : originalImage;

        final List<int> compressedBytes =
            img.encodeJpg(resizedImage, quality: 85);

        await imageFile.writeAsBytes(compressedBytes);
      }

      setState(() {
        if (_activePhotoSlot == 'front') {
          _cleanupPhotoFile(_frontPhoto);
          _frontPhoto = photo;
        } else if (_activePhotoSlot == 'label') {
          _cleanupPhotoFile(_labelPhoto);
          _labelPhoto = photo;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_activePhotoSlot == 'front' ? 'Front' : 'UPC/Label'} photo captured!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Trigger scanning for label photos
      if (_activePhotoSlot == 'label') {
        await _scanLabelPhoto(photo);
        // Also scan for VIN in vehicle recalls
        if (_isVehicleRecall) {
          await _scanForVin(photo);
        }
      }
      // For front photos on vehicle recalls, scan for VIN barcode
      if (_activePhotoSlot == 'front' && _isVehicleRecall) {
        await _scanForVin(photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery(String slot) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          if (slot == 'front') {
            _cleanupPhotoFile(_frontPhoto);
            _frontPhoto = photo;
          } else if (slot == 'label') {
            _cleanupPhotoFile(_labelPhoto);
            _labelPhoto = photo;
          }
          _activePhotoSlot = slot;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${slot == 'front' ? 'Front' : 'UPC/Label'} photo added!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // Trigger scanning for label photos
        if (slot == 'label') {
          await _scanLabelPhoto(photo);
          // Also scan for VIN in vehicle recalls
          if (_isVehicleRecall) {
            await _scanForVin(photo);
          }
        }
        // For front photos on vehicle recalls, scan for VIN barcode
        if (slot == 'front' && _isVehicleRecall) {
          await _scanForVin(photo);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Scan the label photo for UPC/barcode and OCR data
  Future<void> _scanLabelPhoto(XFile photo) async {
    if (!mounted) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Scan the label photo
      final scanResult = await _scanService.scanLabelImage(photo);

      if (!mounted) return;

      // Populate fields from scan results
      bool foundData = false;

      // UPC code from barcode
      if (scanResult.detectedBarcode != null &&
          scanResult.detectedBarcode!.isNotEmpty &&
          _upcController.text.isEmpty) {
        _upcController.text = scanResult.detectedBarcode!;
        foundData = true;
      }

      // Product info from UPC lookup
      if (scanResult.upcResult?.found == true) {
        if (_brandNameController.text.isEmpty &&
            scanResult.upcResult?.brandName != null) {
          _brandNameController.text = scanResult.upcResult!.brandName!;
        }
        if (_itemNameController.text.isEmpty &&
            scanResult.upcResult?.productName != null) {
          _itemNameController.text = scanResult.upcResult!.productName!;
        }
        foundData = true;
      }

      // Label OCR data - extract from extractedFields
      if (scanResult.labelResult != null && scanResult.labelResult!.success) {
        for (final field in scanResult.labelResult!.extractedFields) {
          switch (field.fieldType) {
            case LabelFieldType.modelNumber:
              if (_modelNumberController.text.isEmpty && field.value.isNotEmpty) {
                _modelNumberController.text = field.value;
                foundData = true;
              }
              break;
            case LabelFieldType.batchLotCode:
              if (_batchLotCodeController.text.isEmpty && field.value.isNotEmpty) {
                _batchLotCodeController.text = field.value;
                foundData = true;
              }
              break;
            case LabelFieldType.upc:
              if (_upcController.text.isEmpty && field.value.isNotEmpty) {
                _upcController.text = field.value;
                foundData = true;
              }
              break;
            case LabelFieldType.brandName:
              if (_brandNameController.text.isEmpty && field.value.isNotEmpty) {
                _brandNameController.text = field.value;
                foundData = true;
              }
              break;
            case LabelFieldType.productName:
              if (_itemNameController.text.isEmpty && field.value.isNotEmpty) {
                _itemNameController.text = field.value;
                foundData = true;
              }
              break;
            default:
              break;
          }
        }
      }

      setState(() {
        _isScanning = false;
      });

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              foundData
                  ? 'Scan complete - fields updated!'
                  : 'No additional data found in image',
            ),
            backgroundColor: foundData ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        debugPrint('Scan failed: $e');
        // Don't show error - scanning is optional
      }
    }
  }

  /// Scan the label photo for VIN barcode (for vehicle recalls)
  Future<void> _scanForVin(XFile photo) async {
    if (!_isVehicleRecall || !mounted) return;

    try {
      // Scan for barcode that might be a VIN
      final barcodeScan = await _barcodeScanService.scanFromXFile(photo);

      if (barcodeScan.found && barcodeScan.barcode != null) {
        final potentialVin = barcodeScan.barcode!.toUpperCase().replaceAll(RegExp(r'[^A-HJ-NPR-Z0-9]'), '');

        // VINs are exactly 17 characters
        if (potentialVin.length == 17 && _vinController.text.isEmpty) {
          _vinController.text = potentialVin;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('VIN detected! Decoding...'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 1),
              ),
            );
          }

          // Auto-decode the VIN
          await _decodeVin();
        }
      }
    } catch (e) {
      debugPrint('VIN scan failed: $e');
    }
  }

  /// Decode VIN and populate vehicle details
  Future<void> _decodeVin() async {
    final vin = _vinController.text.trim();
    if (vin.length != 17) return;

    setState(() {
      _isDecodingVin = true;
    });

    try {
      final result = await _vinDecodeService.decodeVin(vin);

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _vinDecoded = true;
          // Populate fields from VIN decode
          if (result.make != null && _brandNameController.text.isEmpty) {
            _brandNameController.text = result.make!;
          }
          if (result.model != null && _itemNameController.text.isEmpty) {
            _itemNameController.text = result.model!;
          }
          if (result.year != null && _modelNumberController.text.isEmpty) {
            // Use model number field for year
            _modelNumberController.text = result.year!;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VIN decoded: ${result.year ?? ''} ${result.make ?? ''} ${result.model ?? ''}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VIN decode failed: ${result.errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VIN decode error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDecodingVin = false;
        });
      }
    }
  }

  void _selectPhotoSlot(String slot) {
    setState(() {
      _activePhotoSlot = slot;
    });

    // Initialize camera if not already done
    if (!_isCameraInitialized && _errorMessage == null) {
      _requestCameraPermission();
    }
  }

  Future<List<String>> _convertPhotosToBase64() async {
    final List<String> photoData = [];

    try {
      if (_frontPhoto != null) {
        final file = File(_frontPhoto!.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        photoData.add('data:image/jpeg;base64,$base64String');
      }

      if (_labelPhoto != null) {
        final file = File(_labelPhoto!.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        photoData.add('data:image/jpeg;base64,$base64String');
      }
    } catch (e) {
      debugPrint('Error converting photos to base64: $e');
    }

    return photoData;
  }

  Future<void> _saveAndEnroll() async {
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

    if (_itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item Name is required'),
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
      // Convert photos to base64
      final photoData = await _convertPhotosToBase64();

      // Create the user item
      if (_isVehicleRecall) {
        // Vehicle-specific item creation
        await _recallMatchService.createUserItem(
          homeId: _selectedHome!.id,
          roomId: _selectedRoom!.id,
          manufacturer: '',
          brandName: _brandNameController.text.trim(), // Make
          productName: _itemNameController.text.trim(), // Model
          modelNumber: '', // Not used for vehicles
          upc: '',
          sku: '',
          batchLotCode: '',
          serialNumber: '',
          photoUrls: photoData,
          itemCategory: 'vehicle',
          vehicleMake: _brandNameController.text.trim(),
          vehicleModel: _itemNameController.text.trim(),
          vehicleYear: _modelNumberController.text.trim(),
          vehicleVin: _vinController.text.trim(),
        );
      } else {
        // Regular item creation
        await _recallMatchService.createUserItem(
          homeId: _selectedHome!.id,
          roomId: _selectedRoom!.id,
          manufacturer: '',
          brandName: _brandNameController.text.trim(),
          productName: _itemNameController.text.trim(),
          modelNumber: _modelNumberController.text.trim(),
          upc: _upcController.text.trim(),
          sku: '',
          batchLotCode: _batchLotCodeController.text.trim(),
          serialNumber: '',
          photoUrls: photoData,
        );
      }

      // Enroll in RMC
      final enrollment = await _apiService.enrollRecallInRmc(
        recallId: widget.recall.databaseId!,
        rmcStatus: 'Not Started',
      );

      if (!mounted) return;

      // Navigate to RMC Details page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RmcDetailsPage(
            recall: widget.recall,
            enrollment: enrollment,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving item: $e'),
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

  Widget _buildPhotoSlot({
    required String slot,
    required String label,
    required IconData icon,
    XFile? photo,
  }) {
    final bool isSelected = _activePhotoSlot == slot;
    final bool hasPhoto = photo != null;
    final bool isLabelScanning = _isScanning && slot == 'label';

    return GestureDetector(
      onTap: () => _selectPhotoSlot(slot),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: hasPhoto
              ? AppColors.secondary
              : AppColors.secondary.withValues(alpha: 0.5),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB300)
                : hasPhoto
                    ? AppColors.accentBlue
                    : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasPhoto)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: Colors.white70,
                          size: 40,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                if (hasPhoto)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
            // Scanning overlay
            if (isLabelScanning)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Scanning...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
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
        title: const Text(
          'Add Item from Recall',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recall info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.recall.agency,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.recall.productName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.recall.brandName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.recall.brandName,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Photos section
              const Text(
                'PHOTOS (OPTIONAL)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Photo slots row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPhotoSlot(
                    slot: 'front',
                    label: 'FRONT',
                    icon: Icons.inventory_2_outlined,
                    photo: _frontPhoto,
                  ),
                  const SizedBox(width: 16),
                  _buildPhotoSlot(
                    slot: 'label',
                    label: 'UPC/Label',
                    icon: Icons.qr_code_scanner,
                    photo: _labelPhoto,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Camera preview (only show if a slot is selected)
              if (_activePhotoSlot != null) ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _isCameraInitialized
                        ? CameraPreview(_cameraController!)
                        : const CustomLoadingIndicator(
                            size: LoadingIndicatorSize.small,
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Camera buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _capturePhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _pickImageFromGallery(_activePhotoSlot!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library, size: 20),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Form fields
              const Text(
                'ITEM DETAILS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Brand Name / Make
              _buildLabeledTextField(
                label: _isVehicleRecall ? 'Make *' : 'Brand Name *',
                controller: _brandNameController,
              ),
              const SizedBox(height: 16),

              // Item Name / Model
              _buildLabeledTextField(
                label: _isVehicleRecall ? 'Model *' : 'Item Name *',
                controller: _itemNameController,
              ),
              const SizedBox(height: 16),

              // Model Number / Year
              _buildLabeledTextField(
                label: _isVehicleRecall ? 'Year' : 'Model Number',
                controller: _modelNumberController,
                keyboardType: _isVehicleRecall ? TextInputType.number : TextInputType.text,
              ),
              const SizedBox(height: 16),

              // UPC (not for vehicles)
              if (!_isVehicleRecall) ...[
                _buildLabeledTextField(
                  label: 'UPC Code',
                  controller: _upcController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],

              // Batch/Lot Code (not for vehicles)
              if (!_isVehicleRecall) ...[
                _buildLabeledTextField(
                  label: 'Batch/Lot Code',
                  controller: _batchLotCodeController,
                ),
                const SizedBox(height: 16),
              ],

              // VIN Field (only for vehicle recalls)
              if (_isVehicleRecall) ...[
                const SizedBox(height: 8),
                const Text(
                  'VIN (Vehicle Identification Number)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _vinController,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 17,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter 17-character VIN',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                          counterText: '',
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
                          suffixIcon: _vinDecoded
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                        onChanged: (value) {
                          // Reset decoded state when VIN changes
                          if (_vinDecoded) {
                            setState(() {
                              _vinDecoded = false;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isDecodingVin || _vinController.text.trim().length != 17
                            ? null
                            : _decodeVin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isDecodingVin
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Decode'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Take a photo of your VIN barcode or enter it manually',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),

              // Home/Room selection
              const Text(
                'LOCATION',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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
                const CustomLoadingIndicator(size: LoadingIndicatorSize.small)
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
                      onTap: () {
                        setState(() {
                          _selectedHome = home;
                          _selectedRoom = null;
                        });
                        _loadRoomsForHome(home.id);
                      },
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
                const CustomLoadingIndicator(size: LoadingIndicatorSize.small)
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
                      onTap: () {
                        setState(() {
                          _selectedRoom = room;
                        });
                      },
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
                const SizedBox(height: 16),
                Text(
                  'Item goes to: ${_selectedHome!.name} → ${_selectedRoom!.name}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndEnroll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFFFF9800).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Save & Start Recall Resolution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
}
