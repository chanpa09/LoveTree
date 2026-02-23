import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/models/event_model.dart';
import '../../core/models/todo_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lovetree.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        couple_id TEXT,
        title TEXT,
        description TEXT,
        date TEXT,
        color_index INTEGER,
        updated_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        couple_id TEXT,
        task TEXT,
        is_done INTEGER,
        updated_at TEXT
      )
    ''');
  }

  // Events CRUD
  Future<int> insertEvent(EventModel event) async {
    final db = await database;
    return await db.insert('events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EventModel>> getEvents(String coupleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'couple_id = ?',
      whereArgs: [coupleId],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) => EventModel.fromMap(maps[i]));
  }

  Future<String?> getLastUpdatedAt(String tableName, String coupleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['updated_at'],
      where: 'couple_id = ?',
      whereArgs: [coupleId],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['updated_at'] as String;
    }
    return null;
  }

  // Todos CRUD
  Future<int> insertTodo(TodoModel todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TodoModel>> getTodos(String coupleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'couple_id = ?',
      whereArgs: [coupleId],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => TodoModel.fromMap(maps[i]));
  }

  Future<int> updateTodoStatus(String id, bool isDone) async {
    final db = await database;
    return await db.update(
      'todos',
      {'is_done': isDone ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTodo(String id) async {
    final db = await database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
