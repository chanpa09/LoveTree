import 'package:cloud_firestore/cloud_firestore.dart';

/// 할 일(Todo) 데이터를 관리하는 모델 클래스입니다.
class TodoModel {
  /// 할 일의 고유 식별자 (Firestore 문서 ID)
  final String id;
  /// 해당 할 일이 속한 커플의 고유 ID
  final String coupleId;
  /// 할 일 내용 (예: "장보러 가기")
  final String task;
  /// 완료 여부 (true: 완료, false: 미완료)
  final bool isDone;
  /// 마지막으로 업데이트된 시간
  final DateTime updatedAt;

  TodoModel({
    required this.id,
    required this.coupleId,
    required this.task,
    required this.isDone,
    required this.updatedAt,
  });

  /// 이 모델 객체를 로컬 SQLite 저장을 위한 Map 형태로 변환합니다.
  /// SQLite는 boolean 형식을 지원하지 않으므로 isDone을 1/0으로 변환합니다.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'couple_id': coupleId,
      'task': task,
      'is_done': isDone ? 1 : 0, // sqflite용
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 특정 필드를 변경한 새로운 객체를 생성하여 반환합니다.
  TodoModel copyWith({
    String? id,
    String? coupleId,
    String? task,
    bool? isDone,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      task: task ?? this.task,
      isDone: isDone ?? this.isDone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// SQLite 등에서 가져온 Map 데이터를 사용하여 TodoModel 객체를 생성합니다.
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      task: map['task'] as String,
      isDone: (map['is_done'] as int) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Firestore의 [DocumentSnapshot]을 사용하여 TodoModel 객체를 생성합니다.
  factory TodoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoModel(
      id: doc.id,
      coupleId: data['couple_id'] as String,
      task: data['task'] as String,
      isDone: data['is_done'] as bool,
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// 이 객체를 Firestore에 저장하기 위한 Map 형태로 변환합니다.
  Map<String, dynamic> toFirestore() {
    return {
      'couple_id': coupleId,
      'task': task,
      'is_done': isDone,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
