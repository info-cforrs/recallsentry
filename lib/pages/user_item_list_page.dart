import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/user_item_card.dart';
import '../models/user_item.dart';
import '../models/user_home.dart';
import '../models/user_room.dart';
import '../services/recallmatch_service.dart';
import 'user_item_details_page.dart';

class UserItemListPage extends StatefulWidget {
  final String? initialRoomFilter;
  final int? initialHomeFilter;
  final Map<int, String>? initialRecallStatuses; // Pre-loaded statuses from parent page

  const UserItemListPage({
    super.key,
    this.initialRoomFilter,
    this.initialHomeFilter,
    this.initialRecallStatuses,
  });

  @override
  State<UserItemListPage> createState() => _UserItemListPageState();
}

class _UserItemListPageState extends State<UserItemListPage> {
  final RecallMatchService _recallMatchService = RecallMatchService();
  final ScrollController _scrollController = ScrollController();
  List<UserItem> _userItems = [];
  List<UserItem> _filteredItems = [];
  Map<int, String> _itemRecallStatuses = {}; // itemId -> status ("Recall Started" or "Needs Review")
  bool _isLoading = true;
  bool _isInitialLoad = true; // Track if this is the first load
  String _searchQuery = '';
  String? _filterByRoom;
  int? _filterByHome;
  bool _sortAZ = false;
  bool _showHeader = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with filters if provided
    _filterByRoom = widget.initialRoomFilter;
    _filterByHome = widget.initialHomeFilter;
    _loadUserItems();

    // Add scroll listener for header hide/show
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;

    // Only toggle when scrolled past threshold (50 pixels)
    if (currentOffset > 50) {
      // Scrolling down
      if (currentOffset > _lastScrollOffset && _showHeader) {
        setState(() => _showHeader = false);
      }
      // Scrolling up
      else if (currentOffset < _lastScrollOffset && !_showHeader) {
        setState(() => _showHeader = true);
      }
    } else {
      // Always show header when near the top
      if (!_showHeader) {
        setState(() => _showHeader = true);
      }
    }

    _lastScrollOffset = currentOffset;
  }

  Future<void> _loadUserItems() async {
    setState(() => _isLoading = true);

    try {
      final items = await _recallMatchService.getUserItems();

      // Use pre-loaded statuses only on initial load, always fetch fresh on refresh
      Map<int, String> statuses = {};
      if (_isInitialLoad && widget.initialRecallStatuses != null && widget.initialRecallStatuses!.isNotEmpty) {
        statuses = Map.from(widget.initialRecallStatuses!);
        _isInitialLoad = false; // Mark initial load as complete
      } else {
        // Load recall statuses for all items (always fetch fresh on refresh)
        try {
          // Get all unique room IDs from items
          final roomIds = items.map((item) => item.roomId).toSet();
          for (final roomId in roomIds) {
            final roomStatuses = await _recallMatchService.getItemRecallStatusesByRoom(roomId);
            statuses.addAll(roomStatuses);
          }
        } catch (e) {
          debugPrint('Warning: Could not fetch recall statuses: $e');
        }
      }

      if (mounted) {
        setState(() {
          _userItems = items;
          _itemRecallStatuses = statuses;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<UserItem> filtered = List.from(_userItems);

    // Apply home filter first (if provided)
    if (_filterByHome != null) {
      filtered = filtered.where((item) => item.homeId == _filterByHome).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final query = _searchQuery.toLowerCase();
        return item.displayName.toLowerCase().contains(query) ||
            item.manufacturer.toLowerCase().contains(query) ||
            item.brandName.toLowerCase().contains(query) ||
            item.productName.toLowerCase().contains(query) ||
            item.modelNumber.toLowerCase().contains(query) ||
            item.upc.toLowerCase().contains(query) ||
            item.sku.toLowerCase().contains(query);
      }).toList();
    }

    // Apply room filter
    if (_filterByRoom != null) {
      filtered = filtered.where((item) => item.roomName == _filterByRoom).toList();
    }

    // Apply sort
    if (_sortAZ) {
      filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A4A5C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterModal(
        sortAZ: _sortAZ,
        filterByRoom: _filterByRoom,
        availableRooms: _userItems.map((item) => item.roomName).toSet().toList()..sort(),
        onApply: (sortAZ, filterByRoom) {
          setState(() {
            _sortAZ = sortAZ;
            _filterByRoom = filterByRoom;
            _applyFilters();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSearchModal() {
    showDialog(
      context: context,
      builder: (context) => _SearchModal(
        initialQuery: _searchQuery,
        onSearch: (query) {
          setState(() {
            _searchQuery = query;
            _applyFilters();
          });
        },
      ),
    );
  }

  void _showItemMenu(UserItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A4A5C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Remove option
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
              title: const Text(
                'Remove',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRemoveConfirmation(item);
              },
            ),

            const Divider(color: Colors.white24),

            // Move option
            ListTile(
              leading: Transform.rotate(
                angle: 3.14159,
                child: const Icon(Icons.double_arrow, color: Color(0xFFFFD700), size: 28),
              ),
              title: const Text(
                'Move',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showMoveDialog(item);
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmation(UserItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A4A5C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirm Deletion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${item.displayName}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _removeItem(item);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeItem(UserItem item) async {
    try {
      await _recallMatchService.deleteUserItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMoveDialog(UserItem item) {
    showDialog(
      context: context,
      builder: (context) => _MoveItemDialog(
        item: item,
        onMoved: () {
          _loadUserItems();
        },
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
          'Item List',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Animated header section (instruction text + action buttons)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showHeader
                ? Column(
                    children: [
                      // Instruction text
                      Container(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        color: AppColors.secondary,
                        child: Center(
                          child: Text(
                            'Long press for options',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      // Action buttons row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: AppColors.secondary,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Filter button
                            GestureDetector(
                              onTap: _showFilterModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A5F7D),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.filter_list, color: Colors.white, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      'Filter',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Search button
                            GestureDetector(
                              onTap: _showSearchModal,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3A5F7D),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          // Main content
          Expanded(
            child: _isLoading
          ? const CustomLoadingIndicator(
              size: LoadingIndicatorSize.medium,
            )
          : _filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onLongPress: () => _showItemMenu(item),
                        child: UserItemCard(
                          item: item,
                          recallStatus: _itemRecallStatuses[item.id],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserItemDetailsPage(item: item),
                              ),
                            );
                            // Refresh statuses when returning (recall status may have changed)
                            if (mounted) {
                              _loadUserItems();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterModal extends StatefulWidget {
  final bool sortAZ;
  final String? filterByRoom;
  final List<String> availableRooms;
  final Function(bool sortAZ, String? filterByRoom) onApply;

  const _FilterModal({
    required this.sortAZ,
    required this.filterByRoom,
    required this.availableRooms,
    required this.onApply,
  });

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  late bool _sortAZ;
  late String? _filterByRoom;

  @override
  void initState() {
    super.initState();
    _sortAZ = widget.sortAZ;
    _filterByRoom = widget.filterByRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter & Sort',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Sort A-Z option
          CheckboxListTile(
            title: const Text(
              'Sort A-Z',
              style: TextStyle(color: Colors.white),
            ),
            value: _sortAZ,
            activeColor: AppColors.accentBlue,
            onChanged: (value) {
              setState(() => _sortAZ = value ?? false);
            },
          ),

          const SizedBox(height: 16),
          const Text(
            'Filter by Room',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Room filter options
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // All Rooms option
              ChoiceChip(
                label: const Text('All Rooms'),
                selected: _filterByRoom == null,
                selectedColor: AppColors.accentBlue,
                backgroundColor: const Color(0xFF3A5F7D),
                labelStyle: TextStyle(
                  color: _filterByRoom == null ? Colors.white : Colors.white70,
                ),
                onSelected: (selected) {
                  setState(() => _filterByRoom = null);
                },
              ),
              // Individual room options
              ...widget.availableRooms.map((room) => ChoiceChip(
                label: Text(room),
                selected: _filterByRoom == room,
                selectedColor: AppColors.accentBlue,
                backgroundColor: const Color(0xFF3A5F7D),
                labelStyle: TextStyle(
                  color: _filterByRoom == room ? Colors.white : Colors.white70,
                ),
                onSelected: (selected) {
                  setState(() => _filterByRoom = room);
                },
              )),
            ],
          ),

          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_sortAZ, _filterByRoom),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
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

class _SearchModal extends StatefulWidget {
  final String initialQuery;
  final Function(String) onSearch;

  const _SearchModal({
    required this.initialQuery,
    required this.onSearch,
  });

  @override
  State<_SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<_SearchModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A4A5C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Search Items',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Search text field
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter search term...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF3A5F7D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSearch(_controller.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveItemDialog extends StatefulWidget {
  final UserItem item;
  final VoidCallback onMoved;

  const _MoveItemDialog({
    required this.item,
    required this.onMoved,
  });

  @override
  State<_MoveItemDialog> createState() => _MoveItemDialogState();
}

class _MoveItemDialogState extends State<_MoveItemDialog> {
  final RecallMatchService _recallMatchService = RecallMatchService();
  List<UserHome> _userHomes = [];
  List<UserRoom> _userRooms = [];
  UserHome? _selectedHome;
  UserRoom? _selectedRoom;
  bool _isLoadingHomes = true;
  bool _isLoadingRooms = false;

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  Future<void> _loadHomes() async {
    setState(() => _isLoadingHomes = true);

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
        setState(() => _isLoadingHomes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load homes: $e')),
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRooms = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rooms: $e')),
        );
      }
    }
  }

  Future<void> _moveItem() async {
    if (_selectedHome == null || _selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both home and room')),
      );
      return;
    }

    try {
      await _recallMatchService.moveUserItem(
        widget.item.id,
        _selectedHome!.id,
        _selectedRoom!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item moved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onMoved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A4A5C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Move to Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 1). SELECT HOME
            const Text(
              '1). SELECT HOME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingHomes)
              const CustomLoadingIndicator(
                size: LoadingIndicatorSize.small,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _userHomes.map((home) {
                  final isSelected = _selectedHome?.id == home.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedHome = home);
                      _loadRoomsForHome(home.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentBlue : const Color(0xFF3A5F7D),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accentBlue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        home.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // 2). SELECT ROOM
            const Text(
              '2). SELECT ROOM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingRooms)
              const CustomLoadingIndicator(
                size: LoadingIndicatorSize.small,
              )
            else if (_userRooms.isEmpty)
              const Text(
                'Select a home first',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _userRooms.map((room) {
                  final isSelected = _selectedRoom?.id == room.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedRoom = room);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentBlue : const Color(0xFF3A5F7D),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accentBlue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        room.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // Move item to display
            if (_selectedHome != null && _selectedRoom != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A5F7D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Move item to:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedHome!.name} → ${_selectedRoom!.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Move Item button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _moveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A6C7D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: 3.14159, // 180 degrees
                      child: const Icon(
                        Icons.double_arrow,
                        color: Color(0xFFFFD700),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Move Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
}
