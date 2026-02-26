import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton sqflite database manager.
class LocalDatabase {
  static const _dbName = 'finecity_landscape.db';
  static const _dbVersion = 1;

  Database? _database;

  /// Returns the database instance, creating it if needed.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Care tasks table
    await db.execute('''
      CREATE TABLE care_tasks (
        id TEXT PRIMARY KEY,
        schedule_id TEXT NOT NULL,
        batch_id TEXT NOT NULL,
        care_type TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        assigned_to TEXT,
        completed_by TEXT,
        completed_at TEXT,
        notes TEXT,
        batch_name TEXT,
        plant_type TEXT,
        zone TEXT,
        location TEXT,
        instructions TEXT,
        batch_image_url TEXT,
        scientific_name TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Plant batches table
    await db.execute('''
      CREATE TABLE plant_batches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        plant_type TEXT NOT NULL,
        scientific_name TEXT,
        category TEXT,
        quantity INTEGER,
        zone TEXT,
        location TEXT,
        image_url TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        updated_at TEXT NOT NULL
      )
    ''');

    // Care schedules table
    await db.execute('''
      CREATE TABLE care_schedules (
        id TEXT PRIMARY KEY,
        batch_id TEXT NOT NULL,
        care_type TEXT NOT NULL,
        frequency_days INTEGER NOT NULL,
        scheduled_time TEXT NOT NULL,
        assigned_to TEXT,
        instructions TEXT,
        start_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    // Sync queue — stores offline completions to push when online
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT NOT NULL,
        action TEXT NOT NULL,
        notes TEXT,
        completed_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Indexes for performance
    await db.execute(
      'CREATE INDEX idx_tasks_scheduled_at ON care_tasks(scheduled_at)',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_status ON care_tasks(status)',
    );
    await db.execute(
      'CREATE INDEX idx_tasks_batch_id ON care_tasks(batch_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_task_id ON sync_queue(task_id)',
    );
  }

  /// Close the database.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
