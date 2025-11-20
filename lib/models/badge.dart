/// Badge model for gamification
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String category; // starter, engagement, mastery, special
  final int? requiredCount; // For count-based badges
  final String? requiredAction; // For action-based badges

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.category,
    this.requiredCount,
    this.requiredAction,
  });

  /// Factory from JSON API response
  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['icon_name'] ?? 'badge_default',
      category: json['category'] ?? 'starter',
      requiredCount: json['required_count'],
      requiredAction: json['required_action'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'category': category,
      'required_count': requiredCount,
      'required_action': requiredAction,
    };
  }

  /// Get badge icon based on iconName
  String getIconAsset() {
    // Will return asset path for badge icons
    return 'assets/badges/$iconName.png';
  }
}

/// User badge progress and unlock data
class UserBadge {
  final String badgeId;
  final Badge badge;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;
  final int requiredProgress;

  UserBadge({
    required this.badgeId,
    required this.badge,
    required this.isUnlocked,
    this.unlockedAt,
    required this.currentProgress,
    required this.requiredProgress,
  });

  /// Factory from JSON API response
  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      badgeId: json['badge_id'],
      badge: Badge.fromJson(json['badge']),
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'])
          : null,
      currentProgress: json['current_progress'] ?? 0,
      requiredProgress: json['required_progress'] ?? 1,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'badge_id': badgeId,
      'badge': badge.toJson(),
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'current_progress': currentProgress,
      'required_progress': requiredProgress,
    };
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (isUnlocked) return 1.0;
    if (requiredProgress <= 0) return 0.0;
    return (currentProgress / requiredProgress).clamp(0.0, 1.0);
  }

  /// Check if badge is ready to unlock
  bool get isReadyToUnlock {
    return !isUnlocked && currentProgress >= requiredProgress;
  }
}

/// Pre-defined starter badges for Rev1
class StarterBadges {
  static Badge get firstAlert => Badge(
        id: 'first_alert',
        name: 'First Alert',
        description: 'Received your first real-time recall alert',
        iconName: 'first_alert',
        category: 'starter',
        requiredCount: 1,
        requiredAction: 'receive_alert',
      );

  static Badge get safetySaver => Badge(
        id: 'safety_saver',
        name: 'Safety Saver',
        description: 'Saved your first recall for later',
        iconName: 'safety_saver',
        category: 'starter',
        requiredCount: 1,
        requiredAction: 'save_recall',
      );

  static Badge get weekWarrior => Badge(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Logged in for 7 consecutive days',
        iconName: 'week_warrior',
        category: 'engagement',
        requiredCount: 7,
        requiredAction: 'login_streak',
      );

  /// Get all starter badges
  static List<Badge> getAllStarter() {
    return [firstAlert, safetySaver, weekWarrior];
  }
}
