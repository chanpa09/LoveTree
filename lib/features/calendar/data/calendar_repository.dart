import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/event_model.dart';
import '../../../data/local/database_helper.dart';

/// 캘린더 일정(Event)의 데이터 처리를 담당하는 리포지토리 클래스입니다.
/// Firestore 원격 DB, SQLite 로컬 DB, 그리고 인메모리 캐시를 통합하여 관리합니다.
class CalendarRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ── 데이터 성능을 위한 캐시 계층 ──
  /// 현재 메모리에 로드된 일정 리스트 (DB 쿼리 부하 감소)
  List<EventModel>? _cachedEvents;
  /// 현재 캐시된 데이터의 커플 ID
  String? _cachedCoupleId;

  /// Firestore에서 변경된 최신 데이터만 가져와 로컬 DB와 동기화합니다 (Delta Sync).
  /// [lastUpdatedStr]을 기준으로 그 이후에 수정된 데이터만 요청하여 네트워크 대역폭을 절약합니다.
  /// 5초 타임아웃을 적용하여 네트워크 불안정 시에도 로컬 데이터로 앱 이용이 가능하도록 합니다.
  Future<void> syncEvents(String coupleId) async {
    try {
      // 1. 로컬 DB에서 마지막 동기화 시간 확인
      final lastUpdatedStr = await _dbHelper.getLastUpdatedAt('events', coupleId);
      
      Query query = _firestore
          .collection('events')
          .where('couple_id', isEqualTo: coupleId);

      // 2. 증분 동기화(Delta Sync) 쿼리 구성
      if (lastUpdatedStr != null) {
        final lastUpdated = DateTime.parse(lastUpdatedStr);
        query = query.where('updated_at', isGreaterThan: Timestamp.fromDate(lastUpdated));
      }

      // 3. 5초 타임아웃 설정 (네트워크 지연 대비 강결합 해제)
      final snapshot = await query.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('동기화 시간 초과'),
      );
      
      // 4. 변경된 문서들 로컬 DB에 반영
      for (var doc in snapshot.docs) {
        final event = EventModel.fromFirestore(doc);
        await _dbHelper.insertEvent(event);
      }

      // 5. 동기화 완료 후 인메모리 캐시도 최신 로컬 DB 데이터로 갱신
      _cachedEvents = await _dbHelper.getEvents(coupleId);
      _cachedCoupleId = coupleId;
    } catch (e) {
      debugPrint('동기화 오류 (로컬 데이터 사용): $e');
    }
  }

  /// 새로운 일정을 생성합니다. 
  /// 사용자가 대기하지 않도록 로컬 DB/캐시에 먼저 저장하고(낙관적 업데이트), 
  /// 서버(Firestore) 전송은 백그라운드에서 비동기로 수행합니다.
  Future<void> addEvent(EventModel event) async {
    final docRef = _firestore.collection('events').doc();
    final eventWithId = EventModel(
      id: docRef.id,
      coupleId: event.coupleId,
      title: event.title,
      description: event.description,
      date: event.date,
      colorIndex: event.colorIndex,
      updatedAt: DateTime.now(), // 로컬 기준 업데이트 시간
    );

    // [Step 1] 로컬 저장소(SQLite)에 즉시 기록
    await _dbHelper.insertEvent(eventWithId);
    
    // [Step 2] 현재 메모리 캐시에도 반영하여 UI 즉시 갱신
    _cachedEvents?.add(eventWithId);
    _cachedEvents?.sort((a, b) => a.date.compareTo(b.date)); // 날짜순 재정렬

    // [Step 3] 서버와 비동기 통신 (실패 시 로그만 기록하며 앱 사용은 방해하지 않음)
    docRef.set(eventWithId.toFirestore()).catchError((e) {
      debugPrint('이벤트 서버 저장 실패: $e');
    });
  }

  /// 로컬 저장소 또는 인메모리 캐시에서 일정 리스트를 가져옵니다.
  /// 동일한 커플 ID로 재요청 시 인메모리 데이터를 반환하여 성능을 최적화합니다.
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

/// 네트워크 지연 시 발생하는 커스텀 예외 클래스입니다.
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});
