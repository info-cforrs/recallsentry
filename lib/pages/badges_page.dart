import 'package:flutter/material.dart';
import '../models/badge.dart';
import '../models/safety_score.dart';
import '../services/gamification_service.dart';
import 'package:rs_flutter/constants/app_colors.dart';

/// Badge showcase page
/// Shows user's unlocked badges and progress on locked badges
class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  final GamificationService _gamificationService = GamificationService();
  List<UserBadge> _badges = [];
  SafetyScore? _safetyScore;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final badges = await _gamificationService.getUserBadges();
      final score = await _gamificationService.getSafetyScore();

      if (mounted) {
        setState(() {
          _badges = badges;
          _safetyScore = score;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Badges',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildBadgeGrid(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load badges',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBadges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid() {
    if (_badges.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate unlocked count
    final unlockedCount = _badges.where((b) => b.isUnlocked).length;

    return Column(
      children: [
        // Header stats
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: AppColors.secondary,
          child: Column(
            children: [
              Text(
                '$unlockedCount / ${_badges.length}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Badges Unlocked',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              if (_safetyScore != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.stars,
                      color: AppColors.accentBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SafetyScore: ${_safetyScore!.score}',
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Badge grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _badges.length,
            itemBuilder: (context, index) {
              return _buildBadgeCard(_badges[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(UserBadge userBadge) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(userBadge),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: userBadge.isUnlocked
                ? AppColors.accentBlue
                : AppColors.border,
            width: 2,
          ),
          boxShadow: userBadge.isUnlocked
              ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Stack(
              alignment: Alignment.center,
              children: [
                // Icon background
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: userBadge.isUnlocked
                        ? AppColors.accentBlue.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getBadgeIcon(userBadge.badge.iconName),
                    size: 32,
                    color: userBadge.isUnlocked
                        ? AppColors.accentBlue
                        : Colors.grey,
                  ),
                ),
                // Lock overlay for locked badges
                if (!userBadge.isUnlocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Badge name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                userBadge.badge.name,
                style: TextStyle(
                  color: userBadge.isUnlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: userBadge.isUnlocked
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Progress bar for locked badges
            if (!userBadge.isUnlocked && userBadge.requiredProgress > 0) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: userBadge.progressPercentage,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentBlue,
                    ),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${userBadge.currentProgress}/${userBadge.requiredProgress}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Badges Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start using RecallSentry to unlock badges and track your safety awareness!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(UserBadge userBadge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: userBadge.isUnlocked
                      ? AppColors.accentBlue.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getBadgeIcon(userBadge.badge.iconName),
                  size: 40,
                  color: userBadge.isUnlocked
                      ? AppColors.accentBlue
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // Badge name
              Text(
                userBadge.badge.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Badge description
              Text(
                userBadge.badge.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Unlock status
              if (userBadge.isUnlocked) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked ${_formatDate(userBadge.unlockedAt)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Column(
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: userBadge.progressPercentage,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentBlue,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${userBadge.currentProgress} / ${userBadge.requiredProgress}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'first_alert':
        return Icons.notifications_active;
      case 'safety_saver':
        return Icons.bookmark;
      case 'week_warrior':
        return Icons.local_fire_department;
      default:
        return Icons.workspace_premium;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}
