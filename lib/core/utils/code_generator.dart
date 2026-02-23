import 'dart:math';

class CodeGenerator {
  /// 8자리 영숫자 초대 코드 (보안 난수 사용, O/0/I/1 제외)
  static String generateInviteCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
