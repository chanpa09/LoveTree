import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/todo_model.dart';
import '../../../data/local/database_helper.dart';

/// 커플의 공동 할 일(Todo) 데이터를 관리하는 저장소 클래스입니다.
/// Firestore 클라우드 저장소와 SQLite 로컬 DB 간의 동기화, 낙관적 업데이트를 통한 빠른 UI 반응성을 담당합니다.
class TodoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Firestore에서 변경된 할 일 데이터만 가져와 로컬 DB와 동기화하는 증분 동기화(Delta Sync)를 수행합니다.
  /// 로컬에 저장된 마지막 업데이트 시간을 기준으로 서버의 최신 변경분만 쿼리합니다.
  Future<void> syncTodos(String coupleId) async {
    try {
      // 1. 로컬 DB에서 마지막 동기화 시간 확인
      final lastUpdatedStr = await _dbHelper.getLastUpdatedAt('todos', coupleId);
      
      Query query = _firestore
          .collection('todos')
          .where('couple_id', isEqualTo: coupleId);

      // 2. 증분 동기화 쿼리 구성
      if (lastUpdatedStr != null) {
        final lastUpdated = DateTime.parse(lastUpdatedStr);
        query = query.where('updated_at', isGreaterThan: Timestamp.fromDate(lastUpdated));
      }

      // 3. 변경된 할 일 데이터 가져오기 (비동기)
      final snapshot = await query.get();
      
      // 4. 로컬 DB에 병합 (Insert or Replace)
      for (var doc in snapshot.docs) {
        final todo = TodoModel.fromFirestore(doc);
        await _dbHelper.insertTodo(todo);
      }
    } catch (e) {
      // 네트워크 오류 시 로그만 남기고 로컬 데이터를 계속 사용하도록 함
      print('할 일 동기화 오류: $e');
    }
  }

  /// 새로운 할 일을 생성합니다. 낙관적 업데이트(Optimistic Update)를 사용하여
  /// 사용자가 입력 즉시 UI에 반영되도록 로컬 DB에 먼저 저장하고 서버 전송은 백그라운드에서 처리합니다.
  Future<void> addTodo(String coupleId, String task) async {
    final docRef = _firestore.collection('todos').doc();
    final todo = TodoModel(
      id: docRef.id,
      coupleId: coupleId,
      task: task,
      isDone: false,
      updatedAt: DateTime.now(),
    );

    // [Step 1] 로컬 DB(SQLite)에 즉시 저장하여 UI 갱신 유도
    await _dbHelper.insertTodo(todo);

    // [Step 2] Firestore 서버 전송 (백그라운드, 서버 응답 대기 안 함)
    docRef.set(todo.toFirestore()).catchError((e) {
      print('할 일 서버 저장 실패: $e');
    });
  }

  /// 할 일의 완료 상태를 토글(체크/해제)합니다.
  /// 낙관적 업데이트를 적용하여 즉각적인 클릭 반응성을 제공합니다.
  Future<void> toggleTodo(TodoModel todo) async {
    final newStatus = !todo.isDone;
    
    // [Step 1] 로컬 DB 상태부터 즉시 업데이트
    await _dbHelper.updateTodoStatus(todo.id, newStatus);
    
    // [Step 2] Firestore 업데이트 (백그라운드)
    _firestore.collection('todos').doc(todo.id).update({
      'is_done': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    }).catchError((e) {
      print('할 일 상태 업데이트 실패: $e');
    });
  }

  /// 할 일을 영구적으로 삭제합니다.
  /// 역시 낙관적 업데이트를 사용하여 목록에서 즉시 제거합니다.
  Future<void> deleteTodo(TodoModel todo) async {
    // [Step 1] 로컬 DB에서 즉시 삭제
    await _dbHelper.deleteTodo(todo.id);

    // [Step 2] Firestore에서 삭제 (백그라운드)
    _firestore.collection('todos').doc(todo.id).delete().catchError((e) {
      print('할 일 서버 삭제 실패: $e');
    });
  }

  /// 로컬 DB에서 해당 커플의 할 일 목록을 가져옵니다.
  /// 오프라인 상태에서도 빠른 데이터 로딩을 보장합니다.
  Future<List<TodoModel>> getLocalTodos(String coupleId) async {
    return await _dbHelper.getTodos(coupleId);
  }
}

/// Riverpod에서 공유될 TodoRepository 프로바이더
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository();
});
