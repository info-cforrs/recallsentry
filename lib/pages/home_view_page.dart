import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/user_home.dart';
import '../models/user_room.dart';
import '../models/user_item.dart';
import '../models/rmc_enrollment.dart';
import '../services/recallmatch_service.dart';
import '../services/api_service.dart';
import '../utils/room_icon_helper.dart';
import 'room_selection_page.dart';
import 'user_item_list_page.dart';
import 'user_item_details_page.dart';
import 'add_new_household_item_photo_page.dart';
import 'add_new_food_item_photo_page.dart';
import 'add_new_vehicle_photo_page.dart';
import 'add_new_tires_photo_page.dart';
import 'add_new_child_seat_photo_page.dart';

/// Home View Page
/// Shows home icon at top with rooms below
/// Long press on home icon: Add Room, Add Item
/// Long press on room: Add Item, Rename Room, Delete Room
/// Tap on room: View items in that room
class HomeViewPage extends StatefulWidget {
  final UserHome home;

  const HomeViewPage({
    super.key,
    required this.home,
  });

  @override
  State<HomeViewPage> createState() => _HomeViewPageState();
}

class _HomeViewPageState extends State<HomeViewPage> with WidgetsBindingObserver {
  final RecallMatchService _service = RecallMatchService();
  List<UserRoom> _rooms = [];
  Map<int, int> _roomItemCounts = {}; // roomId -> item count
  Map<int, int> _roomRecallCounts = {}; // roomId -> recall count (RMC enrolled only)
  Map<int, String> _itemRecallStatuses = {}; // itemId -> status ("Recall Started" or "Needs Review")
  int _homeRecallCount = 0; // Total recall count for the home
  int _homeTotalItems = 0; // Total items in the home
  bool _isLoading = true;
  String? _errorMessage;

  // Garage items (vehicles, tires, child seats) - stored as UserItems, not rooms
  List<UserItem> _garageVehicles = [];
  List<UserItem> _garageTires = [];
  List<UserItem> _garageChildSeats = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRooms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app resumes
      _loadRooms();
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch rooms, items, enrollments, and room counts in PARALLEL for faster loading
      final results = await Future.wait([
        _service.getRoomsByHome(widget.home.id),
        _service.getUserItems(),
        ApiService().fetchRmcEnrollments().catchError((_) => <RmcEnrollment>[]),
        _service.getRmcEnrolledCountsByHome(widget.home.id).catchError((_) => <int, int>{}),
      ]);

      final rooms = results[0] as List<UserRoom>;
      final items = results[1] as List<UserItem>;
      final enrollments = results[2] as List<RmcEnrollment>;
      final recallCounts = results[3] as Map<int, int>; // Per-room counts for room display

      // Count "In Progress" enrollments using SAME logic as Home Page
      // This ensures Home View Page matches Home Page "Recalled Items" count
      int homeRecallCount = 0;
      for (var enrollment in enrollments) {
        final status = enrollment.status.trim().toLowerCase();
        // In Progress: excludes closed, completed, not started, stopped using, mfr contacted
        if (status != 'closed' &&
            status != 'completed' &&
            status != 'not started' &&
            status != 'stopped using' &&
            status != 'mfr contacted') {
          homeRecallCount++;
        }
      }

      // Process items to count per room and categorize garage items
      final Map<int, int> itemCounts = {};
      final List<UserItem> vehicles = [];
      final List<UserItem> tires = [];
      final List<UserItem> childSeats = [];

      for (var item in items) {
        if (item.homeId == widget.home.id) {
          itemCounts[item.roomId] = (itemCounts[item.roomId] ?? 0) + 1;

          // Categorize garage items
          if (item.isVehicle) {
            vehicles.add(item);
          } else if (item.isTires) {
            tires.add(item);
          } else if (item.isChildSeat) {
            childSeats.add(item);
          }
        }
      }

      // Load recall statuses for all rooms in PARALLEL
      Map<int, String> itemStatuses = {};
      try {
        final roomIds = rooms.map((room) => room.id).toList();
        if (roomIds.isNotEmpty) {
          // Fetch all room statuses in parallel
          final statusResults = await Future.wait(
            roomIds.map((roomId) => _service.getItemRecallStatusesByRoom(roomId).catchError((_) => <int, String>{})),
          );
          // Merge all status maps
          for (final statusMap in statusResults) {
            itemStatuses.addAll(statusMap);
          }
        }
      } catch (e) {
        debugPrint('Warning: Could not fetch item recall statuses: $e');
      }

      // Calculate total items in this home
      final totalHomeItems = itemCounts.values.fold(0, (sum, count) => sum + count);

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _roomItemCounts = itemCounts;
          _roomRecallCounts = recallCounts;
          _itemRecallStatuses = itemStatuses;
          _homeRecallCount = homeRecallCount;
          _homeTotalItems = totalHomeItems;
          _garageVehicles = vehicles;
          _garageTires = tires;
          _garageChildSeats = childSeats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading rooms: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showHomeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.meeting_room, color: AppColors.accentBlue),
                title: const Text(
                  'Add Room',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleAddRoom();
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_box, color: AppColors.accentBlue),
                title: const Text(
                  'Add Item',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleAddItemToHome();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showRoomMenu(UserRoom room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  room.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppColors.textDisabled),
              ListTile(
                leading: const Icon(Icons.add_box, color: AppColors.accentBlue),
                title: const Text(
                  'Add Item',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleAddItemToRoom(room);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.warning),
                title: const Text(
                  'Rename Room',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleRenameRoom(room);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  'Delete Room',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeleteRoom(room);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAddRoom() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomSelectionPage(
          home: widget.home,
          onRoomSelected: (roomType, roomName) async {
            await _createRoom(roomType, roomName);
          },
        ),
      ),
    );
  }

  Future<void> _handleAddItemToHome() async {
    // If there are no rooms, prompt user to create one first
    if (_rooms.isEmpty) {
      if (mounted) {
        final createRoom = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.tertiary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'No Rooms',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'You need at least one room before adding items. Would you like to create a room now?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('Create Room'),
                ),
              ],
            );
          },
        );

        if (createRoom == true) {
          _handleAddRoom();
        }
      }
      return;
    }

    // Show item type selection menu (use first room as context)
    _showItemTypeMenu(_rooms.first);
  }

  Future<void> _handleAddItemToRoom(UserRoom room) async {
    // Show item type selection menu
    _showItemTypeMenu(room);
  }

  void _showItemTypeMenu(UserRoom room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.tertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Select Item Type',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: AppColors.textDisabled),
              ListTile(
                leading: Image.asset(
                  'assets/images/household_items_icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.home_outlined, color: AppColors.accentBlue, size: 32);
                  },
                ),
                title: const Text(
                  'Household Items',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleAddHouseholdItem(room);
                },
              ),
              ListTile(
                leading: Image.asset(
                  'assets/images/food_icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.restaurant, color: AppColors.accentBlue, size: 32);
                  },
                ),
                title: const Text(
                  'Food',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleAddFood(room);
                },
              ),
              ListTile(
                leading: Image.asset(
                  'assets/images/vehicle_icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.directions_car, color: AppColors.accentBlue, size: 32);
                  },
                ),
                title: const Text(
                  'Vehicles',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleAddVehicle(room);
                },
              ),
              ListTile(
                leading: Image.asset(
                  'assets/images/tires_icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.trip_origin, color: AppColors.accentBlue, size: 32);
                  },
                ),
                title: const Text(
                  'Tires',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleAddTires(room);
                },
              ),
              ListTile(
                leading: Image.asset(
                  'assets/images/child_seat_icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.child_care, color: AppColors.accentBlue, size: 32);
                  },
                ),
                title: const Text(
                  'Child Seat',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleAddChildSeat(room);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAddHouseholdItem(UserRoom room) async {
    // Navigate to Add New Household Item Photo Page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddNewHouseholdItemPhotoPage(),
      ),
    );
    _loadRooms();
  }

  Future<void> _handleAddFood(UserRoom room) async {
    // Navigate to Add New Food Item Photo Page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddNewFoodItemPhotoPage(),
      ),
    );
    _loadRooms();
  }

  Future<void> _handleAddVehicle(UserRoom room) async {
    // Navigate to Add New Vehicle Photo Page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddNewVehiclePhotoPage(),
      ),
    );
    _loadRooms();
  }

  Future<void> _handleAddTires(UserRoom room) async {
    // Navigate to Add New Tires Photo Page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddNewTiresPhotoPage(),
      ),
    );
    _loadRooms();
  }

  Future<void> _handleAddChildSeat(UserRoom room) async {
    // Navigate to Add New Child Seat Photo Page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddNewChildSeatPhotoPage(),
      ),
    );
    _loadRooms();
  }

  Future<void> _handleRenameRoom(UserRoom room) async {
    final TextEditingController controller = TextEditingController(text: room.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Rename Room',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Room Name',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.accentBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName != room.name) {
      try {
        await _service.updateRoom(
          roomId: room.id,
          name: newName,
          roomType: room.roomType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Renamed to "$newName"'),
              backgroundColor: AppColors.success,
            ),
          );
        }

        _loadRooms();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error renaming room: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _createRoom(String roomType, String roomName) async {
    try {
      await _service.createRoom(
        homeId: widget.home.id,
        name: roomName,
        roomType: roomType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$roomName created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      _loadRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating room: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteRoom(UserRoom room) async {
    final itemCount = _roomItemCounts[room.id] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                itemCount > 0 ? Icons.warning : Icons.delete,
                color: itemCount > 0 ? AppColors.warning : AppColors.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                itemCount > 0 ? 'Warning' : 'Delete Room',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            itemCount > 0
                ? 'This room contains $itemCount item${itemCount == 1 ? '' : 's'}. Deleting this room will also delete all items in it. This action cannot be undone.'
                : 'Are you sure you want to delete "${room.name}"?',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteRoom(room.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${room.name} deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      _loadRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting room: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRoomTap(UserRoom room) async {
    // Navigate to items page filtered by this room
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserItemListPage(
          initialRoomFilter: room.name,
          initialRecallStatuses: _itemRecallStatuses,
        ),
      ),
    );
    _loadRooms();
  }

  Widget _buildHomeIcon() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // Navigate to item list showing all items in this home
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserItemListPage(
                initialHomeFilter: widget.home.id,
                initialRecallStatuses: _itemRecallStatuses,
              ),
            ),
          ).then((_) => _loadRooms());
        },
        onLongPress: _showHomeMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Home icon with item count badge (upper left) and recall count badge (upper right)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Home icon
                  Image.asset(
                    'assets/images/Home_icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home,
                          size: 50,
                          color: AppColors.textPrimary,
                        ),
                      );
                    },
                  ),
                  // Item count badge (upper left) - green
                  if (_homeTotalItems > 0)
                    Positioned(
                      top: -8,
                      left: -8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _homeTotalItems > 99 ? '99+' : _homeTotalItems.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Recall count badge (upper right) - red
                  if (_homeRecallCount > 0)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _homeRecallCount > 99 ? '99+' : _homeRecallCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.home.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to view all items\nLong press for options',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsLayout() {
    // Group rooms by category
    final bedrooms = _rooms.where((r) => r.roomType == 'bedroom').toList();
    final bathrooms = _rooms.where((r) => r.roomType == 'bathroom').toList();

    // Garage rooms (physical spaces)
    final garages = _rooms.where((r) => r.roomType == 'garage').toList();

    // Check if garage section should show (garage rooms OR garage items exist)
    final hasGarageSection = garages.isNotEmpty ||
                             _garageVehicles.isNotEmpty ||
                             _garageTires.isNotEmpty ||
                             _garageChildSeats.isNotEmpty;

    // Individual rooms exclude bedroom, bathroom, and garage
    // Note: vehicle, child_seat, tires are now UserItems, not rooms
    final individualRooms = _rooms.where((r) =>
      r.roomType != 'bedroom' &&
      r.roomType != 'bathroom' &&
      r.roomType != 'garage' &&
      // Legacy room types (for backwards compatibility with existing data)
      r.roomType != 'vehicle' &&
      r.roomType != 'child_seat' &&
      r.roomType != 'tires'
    ).toList();

    // Check if any grouped sections exist
    final hasGroupedSections = bedrooms.isNotEmpty || bathrooms.isNotEmpty || hasGarageSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Individual rooms at top (3-column grid)
        if (individualRooms.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 3,
              ),
              itemCount: individualRooms.length,
              itemBuilder: (context, index) {
                return _buildRoomCard(individualRooms[index]);
              },
            ),
          ),

        // Spacing between individual rooms and first grouped section
        if (individualRooms.isNotEmpty && hasGroupedSections)
          const SizedBox(height: 10),

        // Bedrooms grouped section
        if (bedrooms.isNotEmpty)
          _buildGroupedRoomSection(
            'Bedrooms',
            Icons.bed,
            bedrooms,
          ),

        // Spacing between Bedrooms and next grouped section
        if (bedrooms.isNotEmpty && (bathrooms.isNotEmpty || hasGarageSection))
          const SizedBox(height: 10),

        // Bathrooms grouped section
        if (bathrooms.isNotEmpty)
          _buildGroupedRoomSection(
            'Bathrooms',
            Icons.bathtub,
            bathrooms,
          ),

        // Spacing between Bathrooms and Garage section
        if (bathrooms.isNotEmpty && hasGarageSection)
          const SizedBox(height: 10),

        // Garage and Vehicle(s) grouped section
        if (hasGarageSection)
          _buildGarageVehicleSection(
            garages: garages,
            vehicles: _garageVehicles,
            childSeats: _garageChildSeats,
            tires: _garageTires,
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGroupedRoomSection(String title, IconData icon, List<UserRoom> rooms) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A5F7D), // Teal blue background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rooms grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 3,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              return _buildCompactRoomCard(rooms[index]);
            },
          ),
        ],
      ),
    );
  }

  /// Build the Garage and Vehicle(s) grouped section
  /// Contains: Garage icon, Vehicles (with year/make-model display), Child Seats, Tires
  /// Note: Vehicles, childSeats, and tires are now UserItems (not rooms)
  Widget _buildGarageVehicleSection({
    required List<UserRoom> garages,
    required List<UserItem> vehicles,
    required List<UserItem> childSeats,
    required List<UserItem> tires,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A5F7D), // Teal blue background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with garage icon - long press to add items
          GestureDetector(
            onLongPress: () => _showGarageSectionMenu(garages.isNotEmpty ? garages.first : null),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/garage_white_noBG_icon.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.garage, color: AppColors.textPrimary, size: 28);
                  },
                ),
                const SizedBox(width: 12),
                const Text(
                  'Garage and Vehicle(s)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Vehicles displayed with year on top, make/model below
          if (vehicles.isNotEmpty)
            ...vehicles.map((vehicle) => _buildVehicleCard(vehicle)),

          // Child Seats and Tires in a wrapping layout
          if (childSeats.isNotEmpty || tires.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: vehicles.isNotEmpty ? 12 : 0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Child Seats
                  ...childSeats.map((seat) => _buildCompactGarageItem(seat)),
                  // Tires
                  ...tires.map((tire) => _buildCompactGarageItem(tire)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build a vehicle card with year on top and make/model below
  /// Now uses UserItem instead of UserRoom
  Widget _buildVehicleCard(UserItem vehicle) {
    // Vehicle items don't have room-based counts, use item's own data
    final iconPath = 'assets/images/vehicle_icon.png';

    // Use vehicle-specific fields if available, otherwise parse from display name
    String yearText = vehicle.vehicleYear ?? '';
    String makeModelText = vehicle.vehicleDisplayName;

    // If no vehicle fields, try parsing from product name (legacy support)
    if (yearText.isEmpty && vehicle.productName.isNotEmpty) {
      final nameParts = vehicle.productName.split(' ');
      if (nameParts.isNotEmpty) {
        final firstPart = nameParts.first;
        if (firstPart.length == 4 && int.tryParse(firstPart) != null) {
          yearText = firstPart;
          makeModelText = nameParts.skip(1).join(' ');
        }
      }
    }

    return GestureDetector(
      onTap: () => _handleItemTap(vehicle),
      onLongPress: () => _showItemMenu(vehicle),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Vehicle icon (no badges - items are individual, not containers)
            Image.asset(
              iconPath,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.directions_car,
                  size: 50,
                  color: AppColors.textPrimary,
                );
              },
            ),
            const SizedBox(width: 16),
            // Year on top, Make/Model below
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (yearText.isNotEmpty)
                    Text(
                      yearText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    makeModelText.isNotEmpty ? makeModelText : vehicle.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a compact item card for child seats and tires within garage section
  /// Now uses UserItem instead of UserRoom
  Widget _buildCompactGarageItem(UserItem item) {
    // Get icon based on item category
    String iconPath;
    if (item.isTires) {
      iconPath = 'assets/images/tires_icon.png';
    } else if (item.isChildSeat) {
      iconPath = 'assets/images/child_seat_icon.png';
    } else {
      iconPath = 'assets/images/Home_icon.png';
    }

    return GestureDetector(
      onTap: () => _handleItemTap(item),
      onLongPress: () => _showItemMenu(item),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon (no badges - items are individual, not containers)
            Image.asset(
              iconPath,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.inventory,
                  size: 50,
                  color: AppColors.textPrimary,
                );
              },
            ),
            const SizedBox(height: 6),
            // Item name - use specific display names for garage items to avoid duplicate manufacturer
            Text(
              item.isTires
                  ? item.tireDisplayName
                  : item.isChildSeat
                      ? item.childSeatDisplayName
                      : item.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle tap on a garage item (vehicle, tires, child seat)
  Future<void> _handleItemTap(UserItem item) async {
    // Navigate to item details page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserItemDetailsPage(item: item),
      ),
    );
    // Refresh data when returning (recall status may have changed)
    if (mounted) {
      _loadRooms();
    }
  }

  /// Show menu for garage item (vehicle, tires, child seat)
  void _showItemMenu(UserItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item.isVehicle ? item.fullVehicleName : item.displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.accentBlue),
              title: Text(
                item.isVehicle ? 'Edit Vehicle' : 'Edit Item',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditItemDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                item.isVehicle ? 'Delete Vehicle' : 'Delete Item',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteItemConfirmation(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show menu for garage section (add vehicle, tires, child seat)
  void _showGarageSectionMenu(UserRoom? garageRoom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Garage and Vehicle(s)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.directions_car, color: AppColors.accentBlue),
              title: const Text(
                'Add Vehicle',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                if (garageRoom != null) {
                  _handleAddVehicle(garageRoom);
                } else {
                  // Navigate directly to add vehicle page if no garage room
                  _handleAddVehicle(UserRoom(
                    id: 0,
                    homeId: widget.home.id,
                    homeName: widget.home.name,
                    name: 'Garage',
                    roomType: 'garage',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.tire_repair, color: AppColors.accentBlue),
              title: const Text(
                'Add Tires',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                if (garageRoom != null) {
                  _handleAddTires(garageRoom);
                } else {
                  // Navigate directly to add tires page if no garage room
                  _handleAddTires(UserRoom(
                    id: 0,
                    homeId: widget.home.id,
                    homeName: widget.home.name,
                    name: 'Garage',
                    roomType: 'garage',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.child_care, color: AppColors.accentBlue),
              title: const Text(
                'Add Child Seat',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                if (garageRoom != null) {
                  _handleAddChildSeat(garageRoom);
                } else {
                  // Navigate directly to add child seat page if no garage room
                  _handleAddChildSeat(UserRoom(
                    id: 0,
                    homeId: widget.home.id,
                    homeName: widget.home.name,
                    name: 'Garage',
                    roomType: 'garage',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show edit dialog for vehicle/item
  void _showEditItemDialog(UserItem item) {
    final makeController = TextEditingController(text: item.vehicleMake ?? '');
    final modelController = TextEditingController(text: item.vehicleModel ?? '');
    final yearController = TextEditingController(text: item.vehicleYear ?? '');
    final vinController = TextEditingController(text: item.vehicleVin ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          item.isVehicle ? 'Edit Vehicle' : 'Edit Item',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isVehicle) ...[
                TextField(
                  controller: makeController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Make',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g., Ford, Chevrolet',
                    hintStyle: TextStyle(color: AppColors.textDisabled),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textSecondary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accentBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: modelController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g., F-150, Silverado',
                    hintStyle: TextStyle(color: AppColors.textDisabled),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textSecondary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accentBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: yearController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g., 2024',
                    hintStyle: TextStyle(color: AppColors.textDisabled),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textSecondary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accentBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: vinController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'VIN (optional)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintText: '17-character VIN',
                    hintStyle: TextStyle(color: AppColors.textDisabled),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textSecondary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accentBlue),
                    ),
                  ),
                ),
              ] else ...[
                // For non-vehicle items, just show product name
                TextField(
                  controller: makeController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textSecondary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accentBlue),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateItem(
                item,
                make: makeController.text.trim(),
                model: modelController.text.trim(),
                year: yearController.text.trim(),
                vin: vinController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Update item via API
  Future<void> _updateItem(
    UserItem item, {
    required String make,
    required String model,
    required String year,
    required String vin,
  }) async {
    try {
      // Build product name from make/model
      String productName = '$make $model'.trim();

      await _service.updateUserItem(
        itemId: item.id,
        vehicleMake: make.isNotEmpty ? make : null,
        vehicleModel: model.isNotEmpty ? model : null,
        vehicleYear: year.isNotEmpty ? year : null,
        vehicleVin: vin.isNotEmpty ? vin : null,
        brandName: make.isNotEmpty ? make : null,
        productName: productName.isNotEmpty ? productName : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRooms(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vehicle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteItemConfirmation(UserItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Vehicle?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${item.isVehicle ? item.fullVehicleName : item.displayName}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItem(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Delete item via API
  Future<void> _deleteItem(UserItem item) async {
    try {
      await _service.deleteUserItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRooms(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting vehicle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCompactRoomCard(UserRoom room) {
    final itemCount = _roomItemCounts[room.id] ?? 0;
    final recallCount = _roomRecallCounts[room.id] ?? 0;
    final iconPath = RoomIconHelper.getIconPath(room.roomType);

    return GestureDetector(
      onTap: () => _handleRoomTap(room),
      onLongPress: () => _showRoomMenu(room),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Room Icon with badges
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Room Icon
                  Image.asset(
                    iconPath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.meeting_room,
                        size: 50,
                        color: AppColors.textPrimary,
                      );
                    },
                  ),
                  // Item count badge (upper left) - green
                  if (itemCount > 0)
                    Positioned(
                      top: -6,
                      left: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            itemCount > 99 ? '99+' : '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Recall count badge (upper right) - red
                  if (recallCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            recallCount > 99 ? '99+' : '$recallCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              // Room Name
              Text(
                room.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(UserRoom room) {
    final itemCount = _roomItemCounts[room.id] ?? 0;
    final recallCount = _roomRecallCounts[room.id] ?? 0;
    final iconPath = RoomIconHelper.getIconPath(room.roomType);

    return GestureDetector(
      onTap: () => _handleRoomTap(room),
      onLongPress: () => _showRoomMenu(room),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Room Icon with badges
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Room Icon
                  Image.asset(
                    iconPath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.meeting_room,
                        size: 50,
                        color: AppColors.textPrimary,
                      );
                    },
                  ),
                  // Item count badge (upper left) - green
                  if (itemCount > 0)
                    Positioned(
                      top: -6,
                      left: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            itemCount > 99 ? '99+' : '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Recall count badge (upper right) - red
                  if (recallCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            recallCount > 99 ? '99+' : '$recallCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              // Room Name
              Text(
                room.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
        title: Text(
          '${_rooms.length} room${_rooms.length == 1 ? '' : 's'}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadRooms,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
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
                          ElevatedButton(
                            onPressed: _loadRooms,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              foregroundColor: AppColors.textPrimary,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Home Icon at top
                        _buildHomeIcon(),

                        // Rooms Section
                        if (_rooms.isNotEmpty) ...[
                          _buildRoomsLayout(),
                        ] else ...[
                          // Empty state
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 80,
                                    color: AppColors.textDisabled.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Rooms Yet',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Long press the home icon above to add a room',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }
}
