import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/rmc_enrollment.dart';

/// Database helper for RMC enrollments with offline support
class RmcDatabaseHelper {
  static final RmcDatabaseHelper _instance = RmcDatabaseHelper._internal();
  factory RmcDatabaseHelper() => _instance;
  RmcDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rmc_enrollments.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Main enrollments table
    await db.execute('''
      CREATE TABLE enrollments (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        username TEXT,
        user_email TEXT,
        recall_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        enrolled_at TEXT NOT NULL,
        started_at TEXT,
        stopped_using_at TEXT,
        contacted_manufacturer_at TEXT,
        resolution_started_at TEXT,
        completed_at TEXT,
        updated_at TEXT NOT NULL,
        notes TEXT,
        lot_number TEXT,
        purchase_date TEXT,
        purchase_location TEXT,
        estimated_value REAL,
        recall_data TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Pending sync operations table
    await db.execute('''
      CREATE TABLE pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        enrollment_id INTEGER,
        enrollment_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Index for faster queries
    await db.execute('CREATE INDEX idx_recall_id ON enrollments(recall_id)');
    await db.execute('CREATE INDEX idx_status ON enrollments(status)');
    await db.execute('CREATE INDEX idx_is_synced ON enrollments(is_synced)');
  }

  // ============================================================================
  // ENROLLMENT CRUD OPERATIONS
  // ============================================================================

  /// Insert or update enrollment in local database
  Future<void> saveEnrollment(RmcEnrollment enrollment, {bool isSynced = true}) async {
    final db = await database;

    final enrollmentMap = {
      'id': enrollment.id,
      'user_id': enrollment.userId,
      'username': enrollment.username,
      'user_email': enrollment.userEmail,
      'recall_id': enrollment.recallId,
      'status': enrollment.status,
      'enrolled_at': enrollment.enrolledAt.toIso8601String(),
      'started_at': enrollment.startedAt?.toIso8601String(),
      'stopped_using_at': enrollment.stoppedUsingAt?.toIso8601String(),
      'contacted_manufacturer_at': enrollment.contactedManufacturerAt?.toIso8601String(),
      'resolution_started_at': enrollment.resolutionStartedAt?.toIso8601String(),
      'completed_at': enrollment.completedAt?.toIso8601String(),
      'updated_at': enrollment.updatedAt.toIso8601String(),
      'notes': enrollment.notes,
      'lot_number': enrollment.lotNumber,
      'purchase_date': enrollment.purchaseDate?.toIso8601String().split('T')[0],
      'purchase_location': enrollment.purchaseLocation,
      'estimated_value': enrollment.estimatedValue,
      'recall_data': enrollment.recallData?.toString(),
      'is_synced': isSynced ? 1 : 0,
    };

    await db.insert(
      'enrollments',
      enrollmentMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save multiple enrollments (batch operation)
  Future<void> saveEnrollments(List<RmcEnrollment> enrollments) async {
    final db = await database;
    final batch = db.batch();

    for (final enrollment in enrollments) {
      final enrollmentMap = {
        'id': enrollment.id,
        'user_id': enrollment.userId,
        'username': enrollment.username,
        'user_email': enrollment.userEmail,
        'recall_id': enrollment.recallId,
        'status': enrollment.status,
        'enrolled_at': enrollment.enrolledAt.toIso8601String(),
        'started_at': enrollment.startedAt?.toIso8601String(),
        'stopped_using_at': enrollment.stoppedUsingAt?.toIso8601String(),
        'contacted_manufacturer_at': enrollment.contactedManufacturerAt?.toIso8601String(),
        'resolution_started_at': enrollment.resolutionStartedAt?.toIso8601String(),
        'completed_at': enrollment.completedAt?.toIso8601String(),
        'updated_at': enrollment.updatedAt.toIso8601String(),
        'notes': enrollment.notes,
        'lot_number': enrollment.lotNumber,
        'purchase_date': enrollment.purchaseDate?.toIso8601String().split('T')[0],
        'purchase_location': enrollment.purchaseLocation,
        'estimated_value': enrollment.estimatedValue,
        'recall_data': enrollment.recallData?.toString(),
        'is_synced': 1,
      };

      batch.insert('enrollments', enrollmentMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get all enrollments from local database
  Future<List<RmcEnrollment>> getAllEnrollments() async {
    final db = await database;
    final results = await db.query('enrollments', orderBy: 'updated_at DESC');
    return results.map((map) => _enrollmentFromMap(map)).toList();
  }

  /// Get active enrollments (excluding "Not Active" status)
  Future<List<RmcEnrollment>> getActiveEnrollments() async {
    final db = await database;
    final results = await db.query(
      'enrollments',
      where: 'status != ?',
      whereArgs: ['Not Active'],
      orderBy: 'updated_at DESC',
    );
    return results.map((map) => _enrollmentFromMap(map)).toList();
  }

  /// Get enrollments by status
  Future<List<RmcEnrollment>> getEnrollmentsByStatus(String status) async {
    final db = await database;
    final results = await db.query(
      'enrollments',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'updated_at DESC',
    );
    return results.map((map) => _enrollmentFromMap(map)).toList();
  }

  /// Get enrollment by ID
  Future<RmcEnrollment?> getEnrollmentById(int id) async {
    final db = await database;
    final results = await db.query(
      'enrollments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _enrollmentFromMap(results.first);
  }

  /// Get enrollment for a specific recall
  Future<RmcEnrollment?> getEnrollmentByRecallId(int recallId) async {
    final db = await database;
    final results = await db.query(
      'enrollments',
      where: 'recall_id = ?',
      whereArgs: [recallId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _enrollmentFromMap(results.first);
  }

  /// Delete enrollment from local database
  Future<void> deleteEnrollment(int id) async {
    final db = await database;
    await db.delete(
      'enrollments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unsynced enrollments
  Future<List<RmcEnrollment>> getUnsyncedEnrollments() async {
    final db = await database;
    final results = await db.query(
      'enrollments',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return results.map((map) => _enrollmentFromMap(map)).toList();
  }

  /// Mark enrollment as synced
  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'enrollments',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================================
  // PENDING SYNC OPERATIONS
  // ============================================================================

  /// Add pending sync operation
  Future<void> addPendingSync({
    required String operationType,
    int? enrollmentId,
    required Map<String, dynamic> enrollmentData,
  }) async {
    final db = await database;
    await db.insert('pending_sync', {
      'operation_type': operationType,
      'enrollment_id': enrollmentId,
      'enrollment_data': enrollmentData.toString(),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  /// Get all pending sync operations
  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await database;
    return await db.query('pending_sync', orderBy: 'created_at ASC');
  }

  /// Remove pending sync operation
  Future<void> removePendingSync(int id) async {
    final db = await database;
    await db.delete(
      'pending_sync',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Increment retry count for pending sync
  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_sync SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// Clear all pending sync operations (after successful sync)
  Future<void> clearPendingSync() async {
    final db = await database;
    await db.delete('pending_sync');
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Convert database map to RmcEnrollment
  RmcEnrollment _enrollmentFromMap(Map<String, dynamic> map) {
    return RmcEnrollment(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      username: map['username'] as String?,
      userEmail: map['user_email'] as String?,
      recallId: map['recall_id'] as int,
      status: map['status'] as String,
      enrolledAt: DateTime.parse(map['enrolled_at'] as String),
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : null,
      stoppedUsingAt: map['stopped_using_at'] != null ? DateTime.parse(map['stopped_using_at'] as String) : null,
      contactedManufacturerAt: map['contacted_manufacturer_at'] != null ? DateTime.parse(map['contacted_manufacturer_at'] as String) : null,
      resolutionStartedAt: map['resolution_started_at'] != null ? DateTime.parse(map['resolution_started_at'] as String) : null,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      notes: map['notes'] as String? ?? '',
      lotNumber: map['lot_number'] as String? ?? '',
      purchaseDate: map['purchase_date'] != null ? DateTime.parse(map['purchase_date'] as String) : null,
      purchaseLocation: map['purchase_location'] as String? ?? '',
      estimatedValue: map['estimated_value'] as double?,
      recallData: null, // Recall data stored as string, not parsed for simplicity
    );
  }

  /// Clear all local data (use with caution)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('enrollments');
    await db.delete('pending_sync');
  }

  /// Get database stats for debugging
  Future<Map<String, int>> getStats() async {
    final db = await database;
    final enrollmentCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM enrollments'),
    ) ?? 0;
    final unsyncedCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM enrollments WHERE is_synced = 0'),
    ) ?? 0;
    final pendingSyncCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pending_sync'),
    ) ?? 0;

    return {
      'total_enrollments': enrollmentCount,
      'unsynced_enrollments': unsyncedCount,
      'pending_operations': pendingSyncCount,
    };
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
