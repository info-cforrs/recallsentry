class RmcEnrollment {
  final int id;
  final int userId;
  final String? username;
  final String? userEmail;
  final int recallId;
  final String status;
  final DateTime enrolledAt;
  final DateTime? startedAt;
  final DateTime? stoppedUsingAt;
  final DateTime? contactedManufacturerAt;
  final DateTime? resolutionStartedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final String notes;
  final String lotNumber;
  final DateTime? purchaseDate;
  final String purchaseLocation;
  final double? estimatedValue;
  final String? resolutionBranch; // Track which branch: Return, Repair, Replace, Dispose

  // Optional embedded recall data
  final Map<String, dynamic>? recallData;

  RmcEnrollment({
    required this.id,
    required this.userId,
    this.username,
    this.userEmail,
    required this.recallId,
    required this.status,
    required this.enrolledAt,
    this.startedAt,
    this.stoppedUsingAt,
    this.contactedManufacturerAt,
    this.resolutionStartedAt,
    this.completedAt,
    required this.updatedAt,
    this.notes = '',
    this.lotNumber = '',
    this.purchaseDate,
    this.purchaseLocation = '',
    this.estimatedValue,
    this.resolutionBranch,
    this.recallData,
  });

  factory RmcEnrollment.fromJson(Map<String, dynamic> json) {
    return RmcEnrollment(
      id: json['id'] as int,
      userId: json['user'] as int,
      username: json['username'] as String?,
      userEmail: json['user_email'] as String?,
      recallId: json['recall'] as int,
      status: json['rmc_status'] as String? ?? 'Not Active',
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      stoppedUsingAt: json['stopped_using_at'] != null
          ? DateTime.parse(json['stopped_using_at'] as String)
          : null,
      contactedManufacturerAt: json['contacted_manufacturer_at'] != null
          ? DateTime.parse(json['contacted_manufacturer_at'] as String)
          : null,
      resolutionStartedAt: json['resolution_started_at'] != null
          ? DateTime.parse(json['resolution_started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      notes: json['notes'] as String? ?? '',
      lotNumber: json['lot_number'] as String? ?? '',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : null,
      purchaseLocation: json['purchase_location'] as String? ?? '',
      estimatedValue: json['estimated_value'] != null
          ? double.tryParse(json['estimated_value'].toString())
          : null,
      resolutionBranch: json['resolution_branch'] as String?,
      recallData: json['recall_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'recall': recallId,
      'rmc_status': status,
      'enrolled_at': enrolledAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'stopped_using_at': stoppedUsingAt?.toIso8601String(),
      'contacted_manufacturer_at': contactedManufacturerAt?.toIso8601String(),
      'resolution_started_at': resolutionStartedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'lot_number': lotNumber,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'purchase_location': purchaseLocation,
      'estimated_value': estimatedValue?.toString(),
      'resolution_branch': resolutionBranch,
    };
  }

  RmcEnrollment copyWith({
    int? id,
    int? userId,
    String? username,
    String? userEmail,
    int? recallId,
    String? status,
    DateTime? enrolledAt,
    DateTime? startedAt,
    DateTime? stoppedUsingAt,
    DateTime? contactedManufacturerAt,
    DateTime? resolutionStartedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? notes,
    String? lotNumber,
    DateTime? purchaseDate,
    String? purchaseLocation,
    double? estimatedValue,
    String? resolutionBranch,
    Map<String, dynamic>? recallData,
  }) {
    return RmcEnrollment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userEmail: userEmail ?? this.userEmail,
      recallId: recallId ?? this.recallId,
      status: status ?? this.status,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      startedAt: startedAt ?? this.startedAt,
      stoppedUsingAt: stoppedUsingAt ?? this.stoppedUsingAt,
      contactedManufacturerAt: contactedManufacturerAt ?? this.contactedManufacturerAt,
      resolutionStartedAt: resolutionStartedAt ?? this.resolutionStartedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      lotNumber: lotNumber ?? this.lotNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseLocation: purchaseLocation ?? this.purchaseLocation,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      resolutionBranch: resolutionBranch ?? this.resolutionBranch,
      recallData: recallData ?? this.recallData,
    );
  }
}
