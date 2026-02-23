import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String eventId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      eventId: data['event_id'] as String,
      authorId: data['author_id'] as String,
      content: data['content'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'author_id': authorId,
      'content': content,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
