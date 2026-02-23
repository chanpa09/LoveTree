import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/todo_model.dart';
import '../../../data/local/database_helper.dart';

class TodoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Firestore에서 변경된 할 일 데이터만 가져와 동기화합니다 (Delta Sync)
  Future<void> syncTodos(String coupleId) async {
    final lastUpdatedStr = await _dbHelper.getLastUpdatedAt('todos', coupleId);
    
    Query query = _firestore
        .collection('todos')
        .where('couple_id', isEqualTo: coupleId);

    if (lastUpdatedStr != null) {
      final lastUpdated = DateTime.parse(lastUpdatedStr);
      query = query.where('updated_at', isGreaterThan: Timestamp.fromDate(lastUpdated));
    }

    final snapshot = await query.get();
    
    for (var doc in snapshot.docs) {
      final todo = TodoModel.fromFirestore(doc);
      await _dbHelper.insertTodo(todo);
    }
  }

  /// 새로운 할 일 생성
  Future<void> addTodo(String coupleId, String task) async {
    final docRef = _firestore.collection('todos').doc();
    final todo = TodoModel(
      id: docRef.id,
      coupleId: coupleId,
      task: task,
      isDone: false,
      updatedAt: DateTime.now(),
    );

    await docRef.set(todo.toFirestore());
    await syncTodos(coupleId);
  }

  /// 할 일 상태 토글 (서버와 로컬 동시 반영)
  Future<void> toggleTodo(TodoModel todo) async {
    final newStatus = !todo.isDone;
    // 1. 서버 업데이트
    await _firestore.collection('todos').doc(todo.id).update({
      'is_done': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    // 2. 로컬 업데이트 및 최신 상태 동기화
    await _dbHelper.updateTodoStatus(todo.id, newStatus);
    await syncTodos(todo.coupleId);
  }

  /// 로컬 DB에서 할 일 목록 조회
  Future<List<TodoModel>> getLocalTodos(String coupleId) async {
    return await _dbHelper.getTodos(coupleId);
  }
}

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository();
});
