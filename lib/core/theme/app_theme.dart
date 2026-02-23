import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LoveTree 앱의 일관된 UI/UX 스타일을 정의하는 디자인 시스템 클래스입니다.
/// 모든 고정 컬러, 간격, 테마 설정 및 공통 애니메이션 로직을 포함합니다.
class AppTheme {
  AppTheme._();

  // ── 브랜드 컬러 ──
  /// 메인 브랜드 컬러 (핑크계열)
  static const Color primary = Color(0xFFFF85A1);
  /// 밝은 브랜드 컬러
  static const Color primaryLight = Color(0xFFFFB3C1);
  /// 어두운 브랜드 컬러 (강조용)
  static const Color primaryDark = Color(0xFFE0607E);
  /// 보조 강조 액센트 컬러
  static const Color accent = Color(0xFFFFC2D1);

  // ── 서브 컬러 (상태 및 카테고리용) ──
  static const Color mint = Color(0xFF8CE09C);
  static const Color lavender = Color(0xFFB8A9E8);
  static const Color peach = Color(0xFFFFD4A8);
  static const Color skyBlue = Color(0xFF9DD5F5);

  // ── 뉴트럴 컬러 (텍스트 및 배경) ──
  /// 주요 텍스트 색상
  static const Color textPrimary = Color(0xFF2D2D3A);
  /// 부가 정보용 텍스트 색상
  static const Color textSecondary = Color(0xFF6E6E80);
  /// 힌트 및 비활성 텍스트 색상
  static const Color textHint = Color(0xFFA0A0B0);
  /// 기본 배경색 (매우 연한 핑크톤)
  static const Color surface = Color(0xFFFFF9FA);
  /// 변형 배경색
  static const Color surfaceVariant = Color(0xFFFFF0F5);
  /// 카드 배경색 (순백색)
  static const Color cardColor = Colors.white;
  /// 구분선 색상
  static const Color divider = Color(0xFFF0F0F0);

  // ── 다크모드 전용 컬러 ──
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceVariant = Color(0xFF252540);
  static const Color darkCard = Color(0xFF2A2A45);
  static const Color darkTextPrimary = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFFB0B0C0);

  // ── 이벤트 컬러 팔레트 (캘린더 일정용) ──
  /// 캘린더 일정 생성 시 선택 가능한 8가지 색상 팔레트입니다.
  static const List<Color> eventColors = [
    Color(0xFF5B9BD5), // 블루
    Color(0xFF70C1B3), // 민트
    Color(0xFFFFAE57), // 오렌지
    Color(0xFFFF6B81), // 코랄
    Color(0xFF9B8EC4), // 퍼플
    Color(0xFFE87EA1), // 로즈
    Color(0xFF50C878), // 에메랄드
    Color(0xFFF4A261), // 샌드
  ];

  // ── 그라디언트 정의 ──
  /// 메인 브랜드 그라디언트 (버튼 및 강조 위젯용)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 라이트 모드 기본 배경 그라디언트
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceVariant, surface],
  );

  /// 다크 모드 기본 배경 그라디언트
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkSurfaceVariant, darkSurface],
  );

  // ── 그림자 디자인 ──
  /// 부드러운 강조 그림자
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: primary.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// 카드 위젯용 그림자
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primary.withOpacity(0.05),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ── 둥근 모서리 반지름 (Radius) ──
  static const double radiusS = 12;
  static const double radiusM = 20;
  static const double radiusL = 28;
  static const double radiusXL = 32;

  // ── 라이트 테마 설정 ──
  /// 앱의 전체 라이트 테마 구성을 정의합니다.
  /// [GoogleFonts.notoSansKr] 폰트를 기본으로 사용합니다.
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.notoSansKrTextTheme(
        Theme.of(context).textTheme,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansKr(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          elevation: 0,
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        color: cardColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        backgroundColor: textPrimary,
      ),
    );
  }

  // ── 다크 테마 설정 ──
  /// 시스템 환경이 다크모드일 때 적용될 테마 구성을 정의합니다.
  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.notoSansKrTextTheme(
        ThemeData.dark().textTheme,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
        surface: darkSurface,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansKr(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          elevation: 0,
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        color: darkCard,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        backgroundColor: darkCard,
      ),
    );
  }

  // ── 커스텀 애니메이션 라우트 ──
  /// 화면 전환 시 페이드(Fade)와 미세한 상단 슬라이드(Slide) 효과를 동시에 적용하는 애니메이션 라우트입니다.
  /// 신규 페이지 진입을 더욱 부드럽고 고급스럽게 연출합니다.
  static Route<T> fadeSlideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.05), // 아래에서 위로 살짝 올라오는 효과
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
