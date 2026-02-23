import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/models/event_model.dart';
import '../../core/models/todo_model.dart';

/// SQLite 로컬 데이터베이스 및 웹 환경을 위한 인메모리 캐시를 관리하는 유틸리티 클래스입니다.
/// 싱글톤 패턴으로 구현되어 앱 전체에서 동일한 데이터베이스 인스턴스에 접근합니다.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  // ── 인메모리 캐시 ──
  /// 웹 환경(SQLite 미지원)에서의 데이터 유지 및 모바일에서의 빠른 렌더링을 위한 캐시 리스트입니다.
  final List<EventModel> _eventCache = [];
  final List<TodoModel> _todoCache = [];
  
  /// 마지막으로 동기화된 이벤트/투두의 타임스탬프를 저장하여 증분 동기화에 사용합니다.
  String? _lastEventsUpdateStr;
  String? _lastTodosUpdateStr;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// 데이터베이스 인스턴스를 반환합니다. 
  /// 웹 환경에서는 null을 반환하며 싱글톤 인스턴스가 없는 경우 초기화 과정을 거칩니다.
  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// SQLite 데이터베이스 파일을 생성하고 연결을 시도합니다.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lovetree.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 데이터베이스가 처음 생성될 때 테이블 구조를 정의합니다.
  Future<void> _onCreate(Database db, int version) async {
    // 이벤트 테이블 생성
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
    
    // 할 일(Todo) 테이블 생성
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

  // ── Events CRUD 메서드 ──

  /// 새로운 이벤트를 삽입하거나 기존 이벤트를 업데이트합니다.
  /// 호출 시 인메모리 캐시도 동시에 동기화됩니다.
  Future<int> insertEvent(EventModel event) async {
    // 인메모리 캐시 업데이트 로직
    final index = _eventCache.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      _eventCache[index] = event;
    } else {
      _eventCache.add(event);
      _eventCache.sort((a, b) => a.date.compareTo(b.date)); // 날짜순 정렬
    }

    if (kIsWeb) return 1;
    final db = await database;
    if (db == null) return 0;
    return await db.insert('events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 특정 커플의 전체 이벤트 목록을 가져옵니다.
  /// 모바일에서는 SQLite에서 조회 후 캐시를 갱신하고, 웹에서는 캐시된 데이터를 반환합니다.
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
    
    // 항상 최신 리스트로 캐시 동기화
    _eventCache.clear();
    _eventCache.addAll(list);
    
    return list;
  }

  /// 특정 테이블에서 가장 최근에 업데이트된 데이터의 시간을 문자열로 가져옵니다.
  /// Firestore와의 효율적인 데이터 동기화(증분 업데이트)를 위해 사용됩니다.
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

  // ── Todos CRUD 메서드 ──

  /// 새로운 할 일을 삽입하거나 기존 내용을 업데이트합니다.
  Future<int> insertTodo(TodoModel todo) async {
    final index = _todoCache.indexWhere((t) => t.id == todo.id);
    if (index >= 0) {
      _todoCache[index] = todo;
    } else {
      _todoCache.add(todo);
      _todoCache.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // 최신순 정렬
    }

    if (kIsWeb) return 1;
    final db = await database;
    if (db == null) return 0;
    return await db.insert('todos', todo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 특정 커플의 전체 할 일 목록을 최신순으로 가져옵니다.
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

  /// 할 일의 완료 여부(체크 여부) 상태만 빠르게 업데이트합니다.
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

  /// 특정 ID의 할 일을 영구적으로 삭제합니다.
  Future<int> deleteTodo(String id) async {
    _todoCache.removeWhere((t) => t.id == id);
    
    if (kIsWeb) return 1;
    final db = await database;
    if (db == null) return 0;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
