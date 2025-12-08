import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'package:image/image.dart' as img;
import 'add_new_vehicle_details_page.dart';
import '../services/barcode_scan_service.dart';
import '../services/subscription_service.dart';

enum VehiclePhotoType {
  front,
  back,
  driverSide,
  vin,
  interior,
  other,
}

class AddNewVehiclePhotoPage extends StatefulWidget {
  final bool isQuickCheckMode;
  final SubscriptionTier? quickCheckTier;
  final bool isVerifyRecallMode;

  const AddNewVehiclePhotoPage({
    super.key,
    this.isQuickCheckMode = false,
    this.quickCheckTier,
    this.isVerifyRecallMode = false,
  });

  @override
  State<AddNewVehiclePhotoPage> createState() => _AddNewVehiclePhotoPageState();
}

class _AddNewVehiclePhotoPageState extends State<AddNewVehiclePhotoPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isLoading = true;
  bool _isScanning = false;
  bool _isCapturing = false; // Prevent rapid photo capture
  String? _errorMessage;

  // Selected photo type and captured photos
  VehiclePhotoType? _selectedPhotoType;
  final Map<VehiclePhotoType, XFile?> _capturedPhotos = {};
  final ImagePicker _imagePicker = ImagePicker();
  final BarcodeScanService _barcodeService = BarcodeScanService();

  // Scanned VIN from photo
  String? _scannedVin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't auto-start camera - wait for user to select a photo slot
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();

    // Clean up captured photo files to free memory
    for (final photo in _capturedPhotos.values) {
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

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Dispose camera when app goes to background to free buffers
      if (cameraController != null && cameraController.value.isInitialized) {
        cameraController.dispose();
        _cameraController = null;
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
          });
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize camera when app resumes
      if (_selectedPhotoType != null && _cameraController == null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      await _initializeCamera();
    } else if (status.isDenied) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Camera permission is required to take photos';
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isLoading = false;
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
          _isLoading = false;
          _errorMessage = 'No camera found on this device';
        });
        return;
      }

      // Dispose existing controller if any
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      // Use the first camera (usually back camera)
      // Use medium resolution to prevent buffer overflow issues
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Lock capture orientation for better performance
      await _cameraController!.lockCaptureOrientation();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_selectedPhotoType == null) {
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

    // Prevent rapid photo capture which causes buffer overflow
    if (_isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Small delay to let camera buffers clear
      await Future.delayed(const Duration(milliseconds: 100));

      // Clean up old photo if exists to free buffer
      final oldPhoto = _capturedPhotos[_selectedPhotoType!];
      if (oldPhoto != null) {
        try {
          final oldFile = File(oldPhoto.path);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      final XFile photo = await _cameraController!.takePicture();

      // Compress and resize the image
      final File imageFile = File(photo.path);
      final img.Image? originalImage =
          img.decodeImage(await imageFile.readAsBytes());

      if (originalImage != null) {
        // Resize to max 1200px width while maintaining aspect ratio
        final img.Image resizedImage = originalImage.width > 1200
            ? img.copyResize(originalImage, width: 1200)
            : originalImage;

        // Compress as JPEG with 85% quality
        final List<int> compressedBytes =
            img.encodeJpg(resizedImage, quality: 85);

        // Save compressed image
        await imageFile.writeAsBytes(compressedBytes);
      }

      setState(() {
        _capturedPhotos[_selectedPhotoType!] = photo;
      });

      // If VIN photo was captured, try to scan it
      if (_selectedPhotoType == VehiclePhotoType.vin) {
        await _scanVinFromPhoto(photo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getPhotoTypeLabel(_selectedPhotoType!)} photo captured!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
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
    } finally {
      // Reset capturing flag
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _scanVinFromPhoto(XFile photo) async {
    debugPrint('🔍 Starting VIN barcode scan...');
    try {
      // Try to scan VIN barcode from the photo
      final result = await _barcodeService.scanFromXFile(photo);
      debugPrint('📊 Barcode scan result: found=${result.found}, barcode=${result.barcode}, format=${result.format}');

      if (result.found && result.allBarcodes.isNotEmpty) {
        // Check all detected barcodes for a valid VIN
        for (final barcode in result.allBarcodes) {
          debugPrint('📋 Checking barcode: ${barcode.value} (${barcode.format})');
          // VIN is typically 17 characters, alphanumeric (excluding I, O, Q)
          final cleanedVin = barcode.value.toUpperCase().replaceAll(RegExp(r'[^A-HJ-NPR-Z0-9]'), '');
          debugPrint('📋 Cleaned VIN: $cleanedVin (length: ${cleanedVin.length})');

          if (cleanedVin.length == 17) {
            setState(() {
              _scannedVin = cleanedVin;
            });
            debugPrint('✅ Valid VIN detected: $cleanedVin');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('VIN detected: $cleanedVin'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            return; // Found a valid VIN, stop checking
          }
        }
        // Barcode found but not a valid VIN
        debugPrint('⚠️ Barcode found but not a valid 17-character VIN');
        if (mounted && result.barcode != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Barcode found but not a valid VIN. Please enter VIN manually.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('ℹ️ No barcode detected in image');
      }
    } catch (e) {
      // VIN scan failed silently - user can enter manually
      debugPrint('❌ VIN scan failed: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        // Show dialog to select which slot to place the photo
        if (mounted) {
          final VehiclePhotoType? selectedType = await _showPhotoTypeDialog();
          if (selectedType != null) {
            setState(() {
              _capturedPhotos[selectedType] = photo;
              _selectedPhotoType = selectedType;
            });

            // If VIN photo was selected, try to scan it
            if (selectedType == VehiclePhotoType.vin) {
              await _scanVinFromPhoto(photo);
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('${_getPhotoTypeLabel(selectedType)} photo added!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          }
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

  Future<VehiclePhotoType?> _showPhotoTypeDialog() async {
    return showDialog<VehiclePhotoType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          title: const Text(
            'Select Photo Type',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: VehiclePhotoType.values.map((type) {
              return ListTile(
                title: Text(
                  _getPhotoTypeLabel(type),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _proceedToNextPage() async {
    // Validate that at least one photo is captured
    if (_capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture at least one photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    if (!mounted) return;

    setState(() {
      _isScanning = false;
    });

    // Dispose camera before navigating to prevent buffer overflow
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;

    // Navigate to details page with scanned VIN
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddNewVehicleDetailsPage(
          photos: _capturedPhotos,
          scannedVin: _scannedVin,
          isQuickCheckMode: widget.isQuickCheckMode,
          quickCheckTier: widget.quickCheckTier,
          isVerifyRecallMode: widget.isVerifyRecallMode,
        ),
      ),
    );
  }

  String _getPhotoTypeLabel(VehiclePhotoType type) {
    switch (type) {
      case VehiclePhotoType.front:
        return 'FRONT';
      case VehiclePhotoType.back:
        return 'BACK';
      case VehiclePhotoType.driverSide:
        return 'DRIVER SIDE';
      case VehiclePhotoType.vin:
        return 'VIN/Door Jam';
      case VehiclePhotoType.interior:
        return 'INTERIOR';
      case VehiclePhotoType.other:
        return 'OTHER';
    }
  }

  int get _photoCount => _capturedPhotos.length;

  Widget _buildPhotoSlot(VehiclePhotoType type) {
    final bool isSelected = _selectedPhotoType == type;
    final XFile? photo = _capturedPhotos[type];
    final bool hasPhoto = photo != null;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPhotoType = type;
        });
        // Initialize camera when user selects a photo slot
        if (!_isCameraInitialized && _errorMessage == null) {
          _requestCameraPermission();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto
              ? AppColors.secondary
              : AppColors.secondary.withValues(alpha: 0.5),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB300) // Golden/yellow border for selected
                : hasPhoto
                    ? AppColors.accentBlue
                    : Colors.white24,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasPhoto)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(photo.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              )
            else
              Expanded(
                child: Icon(
                  _getIconData(type),
                  color: Colors.white70,
                  size: 32,
                ),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                _getPhotoTypeLabel(type),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(VehiclePhotoType type) {
    switch (type) {
      case VehiclePhotoType.front:
        return Icons.directions_car;
      case VehiclePhotoType.back:
        return Icons.directions_car;
      case VehiclePhotoType.driverSide:
        return Icons.directions_car;
      case VehiclePhotoType.vin:
        return Icons.qr_code_scanner;
      case VehiclePhotoType.interior:
        return Icons.airline_seat_recline_normal;
      case VehiclePhotoType.other:
        return Icons.camera_alt;
    }
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
          'Add New\nVehicle',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentBlue,
                  ),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage!.contains('settings'))
                            ElevatedButton(
                              onPressed: () {
                                openAppSettings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                              ),
                              child: const Text('Open Settings'),
                            ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo count
                          Text(
                            '$_photoCount PHOTO${_photoCount != 1 ? 'S' : ''} TAKEN',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Photo slots grid (2 rows x 3 columns)
                          SizedBox(
                            height: 180,
                            child: Column(
                              children: [
                                // Top row
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: _buildPhotoSlot(
                                              VehiclePhotoType.front)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _buildPhotoSlot(
                                              VehiclePhotoType.back)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _buildPhotoSlot(
                                              VehiclePhotoType.driverSide)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Bottom row
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: _buildPhotoSlot(
                                              VehiclePhotoType.vin)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _buildPhotoSlot(
                                              VehiclePhotoType.interior)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _buildPhotoSlot(
                                              VehiclePhotoType.other)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // VIN scanned indicator
                          if (_scannedVin != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'VIN Scanned: $_scannedVin',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Camera preview - Full width
                          _selectedPhotoType != null
                              ? Container(
                                  width: double.infinity,
                                  height: 400,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _isCameraInitialized
                                        ? _capturedPhotos[_selectedPhotoType] !=
                                                null
                                            ? Image.file(
                                                File(_capturedPhotos[
                                                        _selectedPhotoType]!
                                                    .path),
                                                fit: BoxFit.contain,
                                              )
                                            : CameraPreview(_cameraController!)
                                        : const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppColors.accentBlue,
                                              ),
                                            ),
                                          ),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 400,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.directions_car_outlined,
                                          size: 64,
                                          color: Colors.white38,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Select a photo slot above\nto start camera',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 24),

                          // Take Photo button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _capturePhoto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.camera_alt),
                              label: Text(
                                _selectedPhotoType != null
                                    ? 'Take ${_getPhotoTypeLabel(_selectedPhotoType!)} Photo'
                                    : 'Take Photo',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Add from phone button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _pickImageFromGallery,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text(
                                'Add Pic from Phone',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Next button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isScanning ? null : _proceedToNextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                disabledBackgroundColor:
                                    const Color(0xFF4CAF50).withValues(alpha: 0.6),
                              ),
                              child: _isScanning
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Processing...',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
