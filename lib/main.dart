import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

/// LoveTree 애플리케이션의 진입점입니다.
/// Firebase 및 AdMob 초기화, 그리고 최상위 위젯인 [LoveTreeApp]을 실행합니다.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [Step 1] Firebase 초기화: 현재 플랫폼(Android, iOS, Web)에 맞는 옵션 적용
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // [Step 2] AdMob 초기화: 웹 버전에서는 광고를 지원하지 않으므로 앱 플랫폼에서만 실행
  if (!kIsWeb) {
    MobileAds.instance.initialize();
  }
  
  // [Step 3] Riverpod의 ProviderScope로 앱을 감싸 상태 관리를 지원함
  runApp(
    const ProviderScope(
      child: LoveTreeApp(),
    ),
  );
}

/// 애플리케이션의 최상위 루트 위젯입니다.
/// 테마 설정(라이트/다크), 앱 이름, 그리고 초기 화면([AuthScreen])을 정의합니다.
class LoveTreeApp extends StatelessWidget {
  const LoveTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LoveTree',
      // AppTheme을 통해 라이트 모드 및 다크 모드 룩앤필을 정의함
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      // 시스템 설정에 따라 테마 자동 전환
      themeMode: ThemeMode.system,
      // 앱의 첫 관문인 인증 및 커플 연결 화면으로 진입
      home: const AuthScreen(),
    );
  }
}
