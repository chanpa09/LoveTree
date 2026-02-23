import 'package:cloud_firestore/cloud_firestore.dart';

/// 일정에 달리는 댓글(방명록/메모) 데이터를 관리하는 모델 클래스입니다.
class CommentModel {
  /// 댓글의 고유 식별자 (Firestore 문서 ID)
  final String id;
  /// 해당 댓글이 달린 이벤트의 고유 ID
  final String eventId;
  /// 댓글 작성자의 고유 UID
  final String authorId;
  /// 댓글 내용
  final String content;
  /// 댓글 작성 시간
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  /// Firestore의 [DocumentSnapshot]을 사용하여 CommentModel 객체를 생성합니다.
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

  /// 이 객체를 Firestore에 저장하기 위한 Map 형태로 변환합니다.
  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'author_id': authorId,
      'content': content,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
