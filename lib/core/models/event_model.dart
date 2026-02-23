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

    // date 필드: Timestamp 또는 String 가능
    DateTime parsedDate;
    final rawDate = data['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    // updated_at 필드: null 가능 (serverTimestamp 미반영)
    DateTime parsedUpdatedAt;
    final rawUpdated = data['updated_at'];
    if (rawUpdated is Timestamp) {
      parsedUpdatedAt = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      parsedUpdatedAt = DateTime.parse(rawUpdated);
    } else {
      parsedUpdatedAt = DateTime.now();
    }

    return EventModel(
      id: doc.id,
      coupleId: data['couple_id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      date: parsedDate,
      colorIndex: data['color_index'] as int? ?? 0,
      updatedAt: parsedUpdatedAt,
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
