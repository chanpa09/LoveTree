import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/event_model.dart';
import '../../../data/local/database_helper.dart';

class CalendarRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Firestore에서 변경된 데이터만 가져와 로컬 DB와 동기화합니다 (Delta Sync)
  Future<void> syncEvents(String coupleId) async {
    // 1. 로컬 DB에서 마지막 업데이트 시간 확인
    final lastUpdatedStr = await _dbHelper.getLastUpdatedAt('events', coupleId);
    
    Query query = _firestore
        .collection('events')
        .where('couple_id', isEqualTo: coupleId);

    if (lastUpdatedStr != null) {
      final lastUpdated = DateTime.parse(lastUpdatedStr);
      query = query.where('updated_at', isGreaterThan: Timestamp.fromDate(lastUpdated));
    }

    // 2. 변경된 데이터만 가져오기
    final snapshot = await query.get();
    
    // 3. 로컬 DB에 저장
    for (var doc in snapshot.docs) {
      final event = EventModel.fromFirestore(doc);
      await _dbHelper.insertEvent(event);
    }
  }

  /// 새로운 일정 생성 (서버와 로컬 동시 반영)
  Future<void> addEvent(EventModel event) async {
    // 1. Firestore에 저장 (updated_at은 서버에서 자동 설정)
    final docRef = _firestore.collection('events').doc();
    final eventWithId = EventModel(
      id: docRef.id,
      coupleId: event.coupleId,
      title: event.title,
      description: event.description,
      date: event.date,
      colorIndex: event.colorIndex,
      updatedAt: DateTime.now(), // 로컬 임시용
    );

    await docRef.set(eventWithId.toFirestore());
    
    // 2. 서버 설정이 반영된 전체 데이터를 다시 읽거나, 
    // 수동으로 updatedAt을 갱신하여 로컬에 저장 (여기서는 편의상 바로 sync 호출 권장)
    await syncEvents(event.coupleId);
  }

  /// 로컬 DB에서 일정 목록 조회
  Future<List<EventModel>> getLocalEvents(String coupleId) async {
    return await _dbHelper.getEvents(coupleId);
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});
