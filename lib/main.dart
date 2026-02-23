import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // AdMob 초기화 (웹에서는 지원되지 않으므로 건너뜀)
  if (!kIsWeb) {
    MobileAds.instance.initialize();
  }
  
  runApp(
    const ProviderScope(
      child: LoveTreeApp(),
    ),
  );
}

class LoveTreeApp extends StatelessWidget {
  const LoveTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LoveTree',
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: ThemeMode.system,
      home: const AuthScreen(),
    );
  }
}
