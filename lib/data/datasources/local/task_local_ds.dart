import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/care_task.dart';
import '../../models/care_task_model.dart';
import 'local_database.dart';

/// Local data source for tasks using sqflite.
abstract class TaskLocalDataSource {
  /// Get all cached tasks for a specific date.
  Future<List<CareTaskModel>> getTasksForDate(DateTime date);

  /// Get today's cached tasks.
  Future<List<CareTaskModel>> getCachedTodayTasks();

  /// Get a single task by ID.
  Future<CareTaskModel?> getTaskById(String id);

  /// Upsert a list of tasks into the local database.
  Future<void> upsertTasks(List<CareTaskModel> tasks);

  /// Cache today's tasks (alias for upsertTasks).
  Future<void> cacheTodayTasks(List<CareTaskModel> tasks);

  /// Mark a task as completed locally.
  Future<CareTaskModel?> completeTaskLocally(
    String id, {
    String? notes,
  });

  /// Get recent completed tasks for a schedule.
  Future<List<CareTaskModel>> getRecentCompletions(
    String scheduleId, {
    int limit = 5,
  });

  /// Add an item to the sync queue for offline completions.
  Future<void> addToSyncQueue({
    required String taskId,
    required String action,
    String? notes,
    required DateTime completedAt,
  });

  /// Get all pending items from the sync queue.
  Future<List<Map<String, dynamic>>> getSyncQueue();

  /// Remove processed items from the sync queue.
  Future<void> clearSyncQueue(List<int> ids);

  /// Clear all cached tasks.
  Future<void> clearCachedTasks();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final LocalDatabase _localDb;

  const TaskLocalDataSourceImpl(this._localDb);

  Future<Database> get _db => _localDb.database;

  @override
  Future<List<CareTaskModel>> getCachedTodayTasks() async {
    return getTasksForDate(DateTime.now());
  }

  @override
  Future<List<CareTaskModel>> getTasksForDate(DateTime date) async {
    final db = await _db;
    final dateStr = date.toIso8601String().split('T')[0];
    final rows = await db.query(
      'care_tasks',
      where: "scheduled_at LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(_rowToModel).toList();
  }

  @override
  Future<CareTaskModel?> getTaskById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'care_tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToModel(rows.first);
  }

  @override
  Future<void> upsertTasks(List<CareTaskModel> tasks) async {
    final db = await _db;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        'care_tasks',
        _modelToRow(task),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> cacheTodayTasks(List<CareTaskModel> tasks) async {
    await upsertTasks(tasks);
  }

  @override
  Future<CareTaskModel?> completeTaskLocally(
    String id, {
    String? notes,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    await db.update(
      'care_tasks',
      {
        'status': 'completed',
        'completed_at': now.toIso8601String(),
        'notes': notes,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return getTaskById(id);
  }

  @override
  Future<List<CareTaskModel>> getRecentCompletions(
    String scheduleId, {
    int limit = 5,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'care_tasks',
      where: "schedule_id = ? AND status = 'completed'",
      whereArgs: [scheduleId],
      orderBy: 'completed_at DESC',
      limit: limit,
    );
    return rows.map(_rowToModel).toList();
  }

  @override
  Future<void> addToSyncQueue({
    required String taskId,
    required String action,
    String? notes,
    required DateTime completedAt,
  }) async {
    final db = await _db;
    await db.insert('sync_queue', {
      'task_id': taskId,
      'action': action,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await _db;
    return db.query('sync_queue', orderBy: 'created_at ASC');
  }

  @override
  Future<void> clearSyncQueue(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete(
      'sync_queue',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  @override
  Future<void> clearCachedTasks() async {
    final db = await _db;
    await db.delete('care_tasks');
  }

  // ─── Row mapping helpers ───

  CareTaskModel _rowToModel(Map<String, dynamic> row) {
    final assignedToStr = row['assigned_to'] as String?;
    List<String> assignedTo = [];
    if (assignedToStr != null && assignedToStr.isNotEmpty) {
      try {
        assignedTo = (jsonDecode(assignedToStr) as List<dynamic>)
            .map((e) => e as String)
            .toList();
      } catch (_) {}
    }

    return CareTaskModel(
      id: row['id'] as String,
      scheduleId: row['schedule_id'] as String,
      batchId: row['batch_id'] as String,
      careType: CareType.fromString(row['care_type'] as String),
      scheduledAt: DateTime.parse(row['scheduled_at'] as String),
      status: TaskStatus.fromString(row['status'] as String),
      assignedTo: assignedTo,
      completedBy: row['completed_by'] as String?,
      completedAt: row['completed_at'] != null
          ? DateTime.tryParse(row['completed_at'] as String)
          : null,
      notes: row['notes'] as String?,
      batchName: row['batch_name'] as String?,
      plantType: row['plant_type'] as String?,
      zone: row['zone'] as String?,
      location: row['location'] as String?,
      instructions: row['instructions'] as String?,
      batchImageUrl: row['batch_image_url'] as String?,
      scientificName: row['scientific_name'] as String?,
    );
  }

  Map<String, dynamic> _modelToRow(CareTaskModel task) {
    return {
      'id': task.id,
      'schedule_id': task.scheduleId,
      'batch_id': task.batchId,
      'care_type': task.careType.name,
      'scheduled_at': task.scheduledAt.toIso8601String(),
      'status': task.status.name,
      'assigned_to': jsonEncode(task.assignedTo),
      'completed_by': task.completedBy,
      'completed_at': task.completedAt?.toIso8601String(),
      'notes': task.notes,
      'batch_name': task.batchName,
      'plant_type': task.plantType,
      'zone': task.zone,
      'location': task.location,
      'instructions': task.instructions,
      'batch_image_url': task.batchImageUrl,
      'scientific_name': task.scientificName,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
