import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/code_generator.dart';

/// 인증 및 커플 연결 관련 데이터 처리를 담당하는 추상 클래스입니다.
abstract class AuthRepository {
  /// 현재 인증된 사용자의 정보를 가져옵니다.
  User? get currentUser;
  /// 익명 로그인을 시도하고 성공 시 사용자 정보를 저장합니다.
  Future<UserModel?> signInAnonymously();
  /// 파트너 초대를 위한 8자리 보안 코드를 생성하여 Firestore에 저장합니다.
  Future<String> createInviteCode(String uid);
  /// 입력된 초대 코드를 검증하고 두 사용자를 하나의 커플 ID로 연결합니다.
  Future<bool> connectWithCode(String uid, String code);
  /// 파트너 없이 혼자 사용하기 위한 솔로 모드 커플을 생성합니다.
  Future<String> startSoloMode(String uid);
}

/// Firebase를 사용한 AuthRepository 인터페이스의 구체적인 구현체입니다.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  User? get currentUser => _auth.currentUser;

  /// 익명 로그인을 수행하고 초기 사용자 문서를 Firestore에 생성합니다.
  @override
  Future<UserModel?> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    if (userCredential.user != null) {
      final user = UserModel(uid: userCredential.user!.uid);
      // 기존 문서가 있는 경우 덮어쓰지 않고 필드만 병합
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
      return user;
    }
    return null;
  }

  /// 새로운 초대 코드를 생성하고 만료 시간(24시간)과 함께 저장합니다.
  @override
  Future<String> createInviteCode(String uid) async {
    final code = CodeGenerator.generateInviteCode();
    await _firestore.collection('codes').doc(code).set({
      'uid': uid,
      'created_at': FieldValue.serverTimestamp(),
      // 24시간 후 만료 (보안 강화)
      'expires_at': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    });
    return code;
  }

  /// 초대 코드를 검증하고 두 사용자를 연결합니다.
  /// 코드 존재 여부, 본인 여부, 만료 여부를 순차적으로 체크합니다.
  @override
  Future<bool> connectWithCode(String uid, String code) async {
    final codeDoc = await _firestore.collection('codes').doc(code).get();

    // 1. 코드 존재 확인
    if (!codeDoc.exists) return false;

    final data = codeDoc.data()!;
    final otherUid = data['uid'] as String;

    // 2. 자기 자신과는 연결 불가
    if (otherUid == uid) return false;

    // 3. 만료 확인 (보안 강화 단계에서 추가)
    final expiresAt = data['expires_at'];
    if (expiresAt != null && expiresAt is Timestamp) {
      if (expiresAt.toDate().isBefore(DateTime.now())) {
        // 이미 만료된 경우 DB에서 삭제 후 실패 반환
        await _firestore.collection('codes').doc(code).delete();
        return false;
      }
    }

    // 4. 커플 문서 생성 (Firestore 자동 ID를 사용하여 예측 불가능하게 함)
    final coupleDoc = _firestore.collection('couples').doc();
    final coupleId = coupleDoc.id;

    final couple = CoupleModel(
      coupleId: coupleId,
      userIds: [uid, otherUid],
      inviteCode: code,
    );

    await coupleDoc.set(couple.toMap());

    // 5. 각 사용자 문서에 생성된 couple_id 업데이트
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'couple_id': coupleId});
    await _firestore
        .collection('users')
        .doc(otherUid)
        .update({'couple_id': coupleId});

    // 6. 사용 완료된 초대 코드 삭제 (일회용 보안 원칙)
    await _firestore.collection('codes').doc(code).delete();

    return true;
  }

  /// 단독 사용자를 위한 임시 커플 그룹을 생성합니다.
  @override
  Future<String> startSoloMode(String uid) async {
    // 보안을 위해 솔로 모드도 자동 생성된 고유 ID 사용
    final coupleDoc = _firestore.collection('couples').doc();
    final coupleId = coupleDoc.id;

    final couple = CoupleModel(
      coupleId: coupleId,
      userIds: [uid],
      inviteCode: '', // 솔로 모드는 초대 코드가 없음
    );

    await coupleDoc.set(couple.toMap());

    await _firestore
        .collection('users')
        .doc(uid)
        .update({'couple_id': coupleId});

    return coupleId;
  }
}

/// UI 및 비즈니스 로직 계층에서 사용할 리포지토리 프로바이더입니다.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});
