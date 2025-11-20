/// SafetyScore model for gamification
class SafetyScore {
  final int score; // 0-100
  final int totalActions;
  final int alertsReceived;
  final int recallsSaved;
  final int filtersCreated;
  final int daysActive;
  final int currentStreak;
  final DateTime? lastUpdated;

  SafetyScore({
    required this.score,
    required this.totalActions,
    required this.alertsReceived,
    required this.recallsSaved,
    required this.filtersCreated,
    required this.daysActive,
    required this.currentStreak,
    this.lastUpdated,
  });

  /// Factory from JSON API response
  factory SafetyScore.fromJson(Map<String, dynamic> json) {
    return SafetyScore(
      score: json['score'] ?? 0,
      totalActions: json['total_actions'] ?? 0,
      alertsReceived: json['alerts_received'] ?? 0,
      recallsSaved: json['recalls_saved'] ?? 0,
      filtersCreated: json['filters_created'] ?? 0,
      daysActive: json['days_active'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'])
          : null,
    );
  }

  /// Factory for empty/initial score
  factory SafetyScore.initial() {
    return SafetyScore(
      score: 0,
      totalActions: 0,
      alertsReceived: 0,
      recallsSaved: 0,
      filtersCreated: 0,
      daysActive: 0,
      currentStreak: 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'total_actions': totalActions,
      'alerts_received': alertsReceived,
      'recalls_saved': recallsSaved,
      'filters_created': filtersCreated,
      'days_active': daysActive,
      'current_streak': currentStreak,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  /// Get score level (0-4)
  /// 0: Beginner (0-20), 1: Aware (21-40), 2: Vigilant (41-60), 3: Guardian (61-80), 4: Safety Hero (81-100)
  int get level {
    if (score >= 81) return 4;
    if (score >= 61) return 3;
    if (score >= 41) return 2;
    if (score >= 21) return 1;
    return 0;
  }

  /// Get level name
  String get levelName {
    switch (level) {
      case 4:
        return 'Safety Hero';
      case 3:
        return 'Guardian';
      case 2:
        return 'Vigilant';
      case 1:
        return 'Aware';
      default:
        return 'Beginner';
    }
  }

  /// Get next level threshold
  int get nextLevelThreshold {
    if (score >= 81) return 100;
    if (score >= 61) return 81;
    if (score >= 41) return 61;
    if (score >= 21) return 41;
    return 21;
  }

  /// Get progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    final currentThreshold = level == 0 ? 0 : (level * 20 + 1);
    final nextThreshold = nextLevelThreshold;
    final range = nextThreshold - currentThreshold;
    final progress = score - currentThreshold;
    return range > 0 ? progress / range : 0.0;
  }
}
