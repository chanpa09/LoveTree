import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../../core/utils/code_generator.dart';

abstract class AuthRepository {
  Future<UserModel?> signInAnonymously();
  Future<String> createInviteCode(String uid);
  Future<bool> connectWithCode(String uid, String code);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    if (userCredential.user != null) {
      final user = UserModel(uid: userCredential.user!.uid);
      // Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
      return user;
    }
    return null;
  }

  @override
  Future<String> createInviteCode(String uid) async {
    final code = CodeGenerator.generateInviteCode();
    // codes 컬렉션에 초대 코드와 생성자 UID 저장
    await _firestore.collection('codes').doc(code).set({
      'uid': uid,
      'created_at': FieldValue.serverTimestamp(),
    });
    return code;
  }

  @override
  Future<bool> connectWithCode(String uid, String code) async {
    final codeDoc = await _firestore.collection('codes').doc(code).get();
    
    if (codeDoc.exists) {
      final otherUid = codeDoc.data()?['uid'] as String;
      if (otherUid == uid) return false; // 자기 자신과는 연결 불가

      final coupleId = '${uid}_$otherUid'; // 단순 커플 ID 생성 전략
      
      // 커플 문서 생성
      final couple = CoupleModel(
        coupleId: coupleId,
        userIds: [uid, otherUid],
        inviteCode: code,
      );
      
      await _firestore.collection('couples').doc(coupleId).set(couple.toMap());
      
      // 두 사용자 문서에 couple_id 업데이트
      await _firestore.collection('users').doc(uid).update({'couple_id': coupleId});
      await _firestore.collection('users').doc(otherUid).update({'couple_id': coupleId});
      
      // 사용된 코드 삭제
      await _firestore.collection('codes').doc(code).delete();
      
      return true;
    }
    return false; 
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});
