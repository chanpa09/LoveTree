import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../../core/utils/code_generator.dart';

abstract class AuthRepository {
  Future<UserModel?> signInAnonymously();
  Future<String> createInviteCode(String uid);
  Future<bool> connectWithCode(String uid, String code);
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> signInAnonymously() async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(uid: 'mock_uid_123');
  }

  @override
  Future<String> createInviteCode(String uid) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return CodeGenerator.generateInviteCode();
  }

  @override
  Future<bool> connectWithCode(String uid, String code) async {
    await Future.delayed(const Duration(seconds: 1));
    // 실제로는 Firestore에서 코드를 조회하여 couple_id를 매핑합니다.
    return code.length == 6; 
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});
