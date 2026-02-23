import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/event_model.dart';
import '../../../data/local/database_helper.dart';

class CalendarRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 인메모리 캐시 — DB 쿼리도 생략 가능
  List<EventModel>? _cachedEvents;
  String? _cachedCoupleId;

  /// Firestore에서 변경된 데이터만 가져와 로컬 DB와 동기화합니다 (Delta Sync)
  /// 5초 타임아웃 적용 — 네트워크가 느려도 로컬 데이터로 진행
  Future<void> syncEvents(String coupleId) async {
    try {
      final lastUpdatedStr = await _dbHelper.getLastUpdatedAt('events', coupleId);
      
      Query query = _firestore
          .collection('events')
          .where('couple_id', isEqualTo: coupleId);

      if (lastUpdatedStr != null) {
        final lastUpdated = DateTime.parse(lastUpdatedStr);
        query = query.where('updated_at', isGreaterThan: Timestamp.fromDate(lastUpdated));
      }

      // 5초 타임아웃
      final snapshot = await query.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('동기화 시간 초과'),
      );
      
      for (var doc in snapshot.docs) {
        final event = EventModel.fromFirestore(doc);
        await _dbHelper.insertEvent(event);
      }

      // 캐시 갱신
      _cachedEvents = await _dbHelper.getEvents(coupleId);
      _cachedCoupleId = coupleId;
    } catch (e) {
      debugPrint('동기화 오류 (로컬 데이터 사용): $e');
    }
  }

  /// 새로운 일정 생성 (낙관적 업데이트: 화면에 즉시 반영)
  Future<void> addEvent(EventModel event) async {
    final docRef = _firestore.collection('events').doc();
    final eventWithId = EventModel(
      id: docRef.id,
      coupleId: event.coupleId,
      title: event.title,
      description: event.description,
      date: event.date,
      colorIndex: event.colorIndex,
      updatedAt: DateTime.now(),
    );

    // 1. 로컬(캐시/DB)에 먼저 저장
    await _dbHelper.insertEvent(eventWithId);
    
    // 인메모리 캐시도 즉시 갱신
    _cachedEvents?.add(eventWithId);

    // 2. 서버 통신은 백그라운드에서 수행
    docRef.set(eventWithId.toFirestore()).catchError((e) {
      debugPrint('이벤트 저장 실패: $e');
    });
  }

  /// 로컬 이벤트 조회 — 인메모리 캐시 우선
  Future<List<EventModel>> getLocalEvents(String coupleId) async {
    if (_cachedCoupleId == coupleId && _cachedEvents != null) {
      return _cachedEvents!;
    }
    final events = await _dbHelper.getEvents(coupleId);
    _cachedEvents = events;
    _cachedCoupleId = coupleId;
    return events;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});
