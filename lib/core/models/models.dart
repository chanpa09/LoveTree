/// 앱의 개별 사용자 정보를 관리하는 모델 클래스입니다.
class UserModel {
  /// 사용자의 고유 UID (Firebase Auth UID)
  final String uid;
  /// 사용자가 속한 커플의 고유 ID (연결되지 않은 경우 null)
  final String? coupleId;
  /// 푸시 알림을 위한 FCM 토큰 (옵션)
  final String? fcmToken;

  UserModel({
    required this.uid,
    this.coupleId,
    this.fcmToken,
  });

  /// 이 모델 객체를 로컬 SQLite 저장 또는 API 통신을 위한 Map 형태로 변환합니다.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'couple_id': coupleId,
      'fcm_token': fcmToken,
    };
  }

  /// Map 데이터를 사용하여 UserModel 객체를 생성합니다.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      coupleId: map['couple_id'] as String?,
      fcmToken: map['fcm_token'] as String?,
    );
  }
}

/// 커플 관계 및 연결 정보를 관리하는 모델 클래스입니다.
class CoupleModel {
  /// 커플 관계의 고유 ID
  final String coupleId;
  /// 커플에 속한 사용자들의 UID 리스트 (일반적으로 2명, 솔로 모드 시 1명)
  final List<String> userIds;
  /// 파트너 연결을 위한 8자리 보안 초대 코드
  final String inviteCode;

  CoupleModel({
    required this.coupleId,
    required this.userIds,
    required this.inviteCode,
  });

  /// 이 모델 객체를 Map 형태로 변환합니다.
  Map<String, dynamic> toMap() {
    return {
      'couple_id': coupleId,
      'user_ids': userIds,
      'invite_code': inviteCode,
    };
  }

  /// Map 데이터를 사용하여 CoupleModel 객체를 생성합니다.
  factory CoupleModel.fromMap(Map<String, dynamic> map) {
    return CoupleModel(
      coupleId: map['couple_id'] as String,
      userIds: List<String>.from(map['user_ids'] as List),
      inviteCode: map['invite_code'] as String,
    );
  }
}
