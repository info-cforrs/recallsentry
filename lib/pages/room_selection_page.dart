import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/room_icon_helper.dart';
import '../models/user_home.dart';

/// Room Selection Page
/// Displays rooms organized by categories with icons
/// Allows users to select a room template and customize the name
class RoomSelectionPage extends StatefulWidget {
  final UserHome home;
  final Function(String roomType, String roomName) onRoomSelected;

  const RoomSelectionPage({
    super.key,
    required this.home,
    required this.onRoomSelected,
  });

  @override
  State<RoomSelectionPage> createState() => _RoomSelectionPageState();
}

class _RoomSelectionPageState extends State<RoomSelectionPage> {
  String? _selectedRoomType;
  final TextEditingController _roomNameController = TextEditingController();
  final List<RoomCategory> _categories = RoomIconHelper.getRoomCategories();

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  void _handleRoomTap(RoomTemplate template) {
    setState(() {
      _selectedRoomType = template.roomType;
      _roomNameController.text = template.defaultName;
    });

    // If room allows multiple instances, show name customization dialog
    if (template.allowMultiple) {
      _showNameCustomizationDialog(template);
    } else {
      // For single-instance rooms, create immediately
      widget.onRoomSelected(template.roomType, template.defaultName);
      Navigator.pop(context);
    }
  }

  void _showNameCustomizationDialog(RoomTemplate template) {
    final suggestedNames = RoomIconHelper.getSuggestedNames(template.roomType);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Image.asset(
                template.iconPath,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.meeting_room,
                    size: 32,
                    color: AppColors.textPrimary,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Customize ${template.defaultName}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a name or create your own:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // Suggested names
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestedNames.map((name) {
                  return ActionChip(
                    label: Text(name),
                    backgroundColor: AppColors.secondary,
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    onPressed: () {
                      setState(() {
                        _roomNameController.text = name;
                      });
                      Navigator.pop(context);
                      _confirmRoomCreation(template.roomType, name);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Custom name input
              TextField(
                controller: _roomNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Custom Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'Enter custom room name',
                  hintStyle: const TextStyle(color: AppColors.textDisabled),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedRoomType = null;
                });
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final customName = _roomNameController.text.trim();
                if (customName.isNotEmpty) {
                  Navigator.pop(context);
                  _confirmRoomCreation(template.roomType, customName);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create Room'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRoomCreation(String roomType, String roomName) {
    widget.onRoomSelected(roomType, roomName);
    Navigator.pop(context);
  }

  Widget _buildCategorySection(RoomCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            category.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Room Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: category.rooms.length,
            itemBuilder: (context, index) {
              final template = category.rooms[index];
              final isSelected = _selectedRoomType == template.roomType;

              return _buildRoomCard(template, isSelected);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRoomCard(RoomTemplate template, bool isSelected) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.accentBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _handleRoomTap(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Room Icon
              Image.asset(
                template.iconPath,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.meeting_room,
                    size: 64,
                    color: AppColors.textPrimary,
                  );
                },
              ),
              const SizedBox(height: 6),
              // Room Name
              Flexible(
                child: Text(
                  template.defaultName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Multiple indicator
              if (template.allowMultiple)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Room Type',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.home.name,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Info banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.accentBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a room type below. Rooms marked with + can be added multiple times with different names.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Category Sections
              ..._categories.map((category) => _buildCategorySection(category)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
