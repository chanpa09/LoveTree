import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final DateTime date;
  final int colorIndex;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.date,
    required this.colorIndex,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'couple_id': coupleId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'color_index': colorIndex,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      coupleId: map['couple_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      colorIndex: map['color_index'] as int,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      coupleId: data['couple_id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      colorIndex: data['color_index'] as int,
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'couple_id': coupleId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'color_index': colorIndex,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
