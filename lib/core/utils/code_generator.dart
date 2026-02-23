import 'dart:math';

class CodeGenerator {
  /// 6자리 숫자로 된 랜덤 초대 코드를 생성합니다.
  static String generateInviteCode() {
    final random = Random();
    return (random.nextInt(900000) + 100000).toString();
  }
}
