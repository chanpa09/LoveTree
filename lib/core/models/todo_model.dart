import 'package:cloud_firestore/cloud_firestore.dart';

class TodoModel {
  final String id;
  final String coupleId;
  final String task;
  final bool isDone;
  final DateTime updatedAt;

  TodoModel({
    required this.id,
    required this.coupleId,
    required this.task,
    required this.isDone,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'couple_id': coupleId,
      'task': task,
      'is_done': isDone ? 1 : 0, // sqflite용
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      task: map['task'] as String,
      isDone: (map['is_done'] as int) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

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

  Map<String, dynamic> toFirestore() {
    return {
      'couple_id': coupleId,
      'task': task,
      'is_done': isDone,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
