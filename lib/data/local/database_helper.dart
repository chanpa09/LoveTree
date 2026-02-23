import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/models/event_model.dart';
import '../../core/models/todo_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  // 웹 지원을 위한 인메모리 캐시 (모바일에서도 빠른 렌더링에 도움을 줄 수 있음)
  final List<EventModel> _eventCache = [];
  final List<TodoModel> _todoCache = [];
  String? _lastEventsUpdateStr;
  String? _lastTodosUpdateStr;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (kIsWeb) return null;
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
    // 인메모리 캐시 업데이트
    final index = _eventCache.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _eventCache[index] = event;
    } else {
      _eventCache.add(event);
      _eventCache.sort((a, b) => a.date.compareTo(b.date));
    }

    if (kIsWeb) return 1;
    final db = await database;
    if (db == null) return 0;
    return await db.insert('events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EventModel>> getEvents(String coupleId) async {
    if (kIsWeb) {
      return _eventCache.where((e) => e.coupleId == coupleId).toList();
    }
    
    final db = await database;
    if (db == null) return _eventCache.where((e) => e.coupleId == coupleId).toList();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'couple_id = ?',
      whereArgs: [coupleId],
      orderBy: 'date ASC',
    );
    
    final list = List.generate(maps.length, (i) => EventModel.fromMap(maps[i]));
    
    // 캐시 동기화
    _eventCache.clear();
    _eventCache.addAll(list);
    
    return list;
  }

  Future<String?> getLastUpdatedAt(String tableName, String coupleId) async {
    if (kIsWeb) {
      return tableName == 'events' ? _lastEventsUpdateStr : _lastTodosUpdateStr;
    }

    final db = await database;
    if (db == null) return null;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['updated_at'],
      where: 'couple_id = ?',
      whereArgs: [coupleId],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final res = maps.first['updated_at'] as String;
      if (tableName == 'events') _lastEventsUpdateStr = res;
      if (tableName == 'todos') _lastTodosUpdateStr = res;
      return res;
    }
    return null;
  }

  // Todos CRUD
  Future<int> insertTodo(TodoModel todo) async {
    final index = _todoCache.indexWhere((t) => t.id == todo.id);
    if (index >= 0) {
      _todoCache[index] = todo;
    } else {
      _todoCache.add(todo);
      _todoCache.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // 최신순
    }

    if (kIsWeb) return 1;
    final db = await database;
    if (db == null) return 0;
    return await db.insert('todos', todo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TodoModel>> getTodos(String coupleId) async {
    if (kIsWeb) {
      return _todoCache.where((t) => t.coupleId == coupleId).toList();
    }

    final db = await database;
    if (db == null) return _todoCache.where((t) => t.coupleId == coupleId).toList();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'couple_id = ?',
      whereArgs: [coupleId],
      orderBy: 'updated_at DESC',
    );
    
    final list = List.generate(maps.length, (i) => TodoModel.fromMap(maps[i]));
    
    _todoCache.clear();
    _todoCache.addAll(list);
    
    return list;
  }

  Future<int> updateTodoStatus(String id, bool isDone) async {
    final index = _todoCache.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _todoCache[index] = _todoCache[index].copyWith(
        isDone: isDone,
        updatedAt: DateTime.now(),
      );
    }

    if (kIsWeb) return 1;
    final db = await database;
    if (db == null) return 0;
    return await db.update(
      'todos',
      {'is_done': isDone ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTodo(String id) async {
    _todoCache.removeWhere((t) => t.id == id);
    
    if (kIsWeb) return 1;
    final db = await database;
    if (db == null) return 0;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
