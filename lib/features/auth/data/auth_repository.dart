import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/code_generator.dart';

abstract class AuthRepository {
  User? get currentUser;
  Future<UserModel?> signInAnonymously();
  Future<String> createInviteCode(String uid);
  Future<bool> connectWithCode(String uid, String code);
  Future<String> startSoloMode(String uid);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserModel?> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    if (userCredential.user != null) {
      final user = UserModel(uid: userCredential.user!.uid);
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
      return user;
    }
    return null;
  }

  @override
  Future<String> createInviteCode(String uid) async {
    final code = CodeGenerator.generateInviteCode();
    await _firestore.collection('codes').doc(code).set({
      'uid': uid,
      'created_at': FieldValue.serverTimestamp(),
      // 24시간 후 만료
      'expires_at': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    });
    return code;
  }

  @override
  Future<bool> connectWithCode(String uid, String code) async {
    final codeDoc = await _firestore.collection('codes').doc(code).get();

    if (!codeDoc.exists) return false;

    final data = codeDoc.data()!;
    final otherUid = data['uid'] as String;

    // 자기 자신과는 연결 불가
    if (otherUid == uid) return false;

    // 만료 확인
    final expiresAt = data['expires_at'];
    if (expiresAt != null && expiresAt is Timestamp) {
      if (expiresAt.toDate().isBefore(DateTime.now())) {
        // 만료된 코드 삭제 후 실패 반환
        await _firestore.collection('codes').doc(code).delete();
        return false;
      }
    }

    // Firestore 자동 ID로 예측 불가능한 커플 ID 생성
    final coupleDoc = _firestore.collection('couples').doc();
    final coupleId = coupleDoc.id;

    final couple = CoupleModel(
      coupleId: coupleId,
      userIds: [uid, otherUid],
      inviteCode: code,
    );

    await coupleDoc.set(couple.toMap());

    // 두 사용자 문서에 couple_id 업데이트
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'couple_id': coupleId});
    await _firestore
        .collection('users')
        .doc(otherUid)
        .update({'couple_id': coupleId});

    // 사용된 코드 삭제
    await _firestore.collection('codes').doc(code).delete();

    return true;
  }

  @override
  Future<String> startSoloMode(String uid) async {
    // Firestore 자동 ID로 예측 불가능한 커플 ID 생성
    final coupleDoc = _firestore.collection('couples').doc();
    final coupleId = coupleDoc.id;

    final couple = CoupleModel(
      coupleId: coupleId,
      userIds: [uid],
      inviteCode: '',
    );

    await coupleDoc.set(couple.toMap());

    await _firestore
        .collection('users')
        .doc(uid)
        .update({'couple_id': coupleId});

    return coupleId;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});
