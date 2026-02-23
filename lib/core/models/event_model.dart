import 'package:cloud_firestore/cloud_firestore.dart';

/// 캘린더에 표시될 일정 데이터를 관리하는 모델 클래스입니다.
class EventModel {
  /// 이벤트의 고유 식별자 (Firestore 문서 ID)
  final String id;
  /// 해당 이벤트가 속한 커플의 고유 ID
  final String coupleId;
  /// 일정 제목 (예: "첫 데이트", "캠핑 가는 날")
  final String title;
  /// 일정에 대한 상세 설명 (옵션)
  final String? description;
  /// 일정이 예정된 날짜 및 시간
  final DateTime date;
  /// 일정 표시 색상 인덱스 (AppTheme.eventColors 참조)
  final int colorIndex;
  /// 마지막으로 데이터가 업데이트된 시간
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

  /// 이 모델 객체를 로컬 SQLite 저장을 위한 Map 형태로 변환합니다.
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

  /// SQLite 등에서 가져온 Map 데이터를 사용하여 EventModel 객체를 생성합니다.
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

  /// Firestore의 [DocumentSnapshot]을 사용하여 EventModel 객체를 생성합니다.
  /// Firestore의 서버 시간(Timestamp) 처리와 null 안정성을 위한 로직이 포함되어 있습니다.
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // date 필드 처리: Timestamp 또는 String 형식 모두 대응 가능하도록 설계
    DateTime parsedDate;
    final rawDate = data['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    // updated_at 필드 처리: Firestore 서버 타임스탬프가 아직 반영되지 않은 경우(null)에 대응
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

  /// 이 객체를 Firestore에 저장하기 위한 Map 형태로 변환합니다.
  /// 'updated_at' 필드는 Firestore 서버에서 관리하는 [FieldValue.serverTimestamp]를 사용합니다.
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
