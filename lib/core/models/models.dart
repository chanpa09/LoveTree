// lib/core/models/user_model.dart
class UserModel {
  final String uid;
  final String? coupleId;
  final String? fcmToken;

  UserModel({
    required this.uid,
    this.coupleId,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'couple_id': coupleId,
      'fcm_token': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      coupleId: map['couple_id'] as String?,
      fcmToken: map['fcm_token'] as String?,
    );
  }
}

// lib/core/models/couple_model.dart
class CoupleModel {
  final String coupleId;
  final List<String> userIds;
  final String inviteCode; // 6자리 무작위 코드

  CoupleModel({
    required this.coupleId,
    required this.userIds,
    required this.inviteCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'couple_id': coupleId,
      'user_ids': userIds,
      'invite_code': inviteCode,
    };
  }

  factory CoupleModel.fromMap(Map<String, dynamic> map) {
    return CoupleModel(
      coupleId: map['couple_id'] as String,
      userIds: List<String>.from(map['user_ids'] as List),
      inviteCode: map['invite_code'] as String,
    );
  }
}
