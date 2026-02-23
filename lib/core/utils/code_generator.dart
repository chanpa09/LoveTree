import 'dart:math';

/// 앱 전체에서 사용되는 고유 코드 생성을 담당하는 유틸리티 클래스입니다.
class CodeGenerator {
  /// 8자리 영숫자 초대 코드를 생성합니다.
  /// 보안을 위해 [Random.secure] (CSPRNG)를 사용하며, 가독성을 위해
  /// 혼동하기 쉬운 문자(O, 0, I, 1)를 제외한 문자열 풀에서 추출합니다.
  static String generateInviteCode() {
    final random = Random.secure();
    // 가독성을 고려하여 O, 0, I, 1을 제외한 문자열 풀
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
