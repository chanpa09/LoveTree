import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/theme/app_theme.dart';

/// 앱의 진입점이자 사용자 인증 및 커플 연결을 담당하는 메인 스크린입니다.
/// 하트 맥박 애니메이션, 초대 코드 생성, 코드 입력 및 파트너 연결 로직을 포함합니다.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  /// 파트너의 초대 코드를 입력받는 컨트롤러
  final TextEditingController _codeController = TextEditingController();
  /// 현재 익명 로그인된 사용자 정보
  UserModel? _currentUser;
  /// 내가 생성한 파트너 초대 코드
  String? _myInviteCode;
  /// 데이터 로딩 상태 (API 요청 중 등)
  bool _isLoading = false;

  // ── 애니메이션 설정 ──
  /// 화면 진입 시 부드럽게 나타나는 페이드 애니메이션
  late AnimationController _fadeController;
  /// 메인 하트 아이콘이 두근거리는 맥박 애니메이션
  late AnimationController _heartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();

    // 진입 페이드 애니메이션 설정 (1.2초 동안 부드럽게)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // 하트 맥박 애니메이션 설정 (끊임없이 반복)
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _heartController,
        curve: Curves.easeInOut,
      ),
    );
    _heartController.repeat(reverse: true);

    _fadeController.forward();
    
    // 화면 진입 시 자동으로 익명 로그인 수행
    _preSignIn();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heartController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 앱 진입 시 초기 익명 로그인을 시도합니다.
  /// 만약 이미 커플 ID가 연결된 사용자라면 바로 캘린더 화면으로 이동합니다.
  void _preSignIn() async {
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);

    try {
      final user = await repo.signInAnonymously().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      // 이미 커플에 연결되어 있다면 메인 화면으로 자동 진입 (자동 로그인 처리)
      if (user?.coupleId != null) {
        _navigateToCalendar(user!.coupleId!);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 파트너에게 보여줄 8자리 보안 초대 코드를 생성합니다.
  void _generateCode() async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final code = await repo.createInviteCode(_currentUser!.uid);
    setState(() {
      _myInviteCode = code;
      _isLoading = false;
    });
  }

  /// 파트너 초대 과정 없이 혼자서 앱을 시작합니다 (솔로 모드).
  void _startSolo() async {
    setState(() => _isLoading = true);
    try {
      // 로그인이 아직 안 된 경우 로그인부터 수행
      if (_currentUser == null) {
        final repo = ref.read(authRepositoryProvider);
        final user = await repo.signInAnonymously();
        if (!mounted) return;
        if (user == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        _currentUser = user;
      }

      final repo = ref.read(authRepositoryProvider);
      final coupleId = await repo.startSoloMode(_currentUser!.uid);
      _navigateToCalendar(coupleId);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 생성된 초대 코드를 클릭 시 클립보드에 복사합니다.
  void _copyCode() {
    if (_myInviteCode == null) return;
    Clipboard.setData(ClipboardData(text: _myInviteCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('초대 코드가 복사되었습니다!'),
            ],
          ),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 파트너가 알려준 코드를 입력하여 두 계정을 하나로 연결합니다.
  void _connect() async {
    // 8자리 코드가 맞는지 먼저 확인 (보안 강화 후 8자리로 변경됨)
    if (_currentUser == null || _codeController.text.length != 8) return;
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final success = await repo.connectWithCode(
        _currentUser!.uid, _codeController.text);

    if (success) {
      // 연결 성공 시 최신 사용자 정보를 가져와 화면 전환
      final updatedUser = await repo.signInAnonymously();
      if (updatedUser?.coupleId != null) {
        _navigateToCalendar(updatedUser!.coupleId!);
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('잘못된 코드이거나 이미 만료된 코드입니다.'),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// 캘린더 화면으로 이동하며 공통 커스터 애니메이션을 적용합니다.
  void _navigateToCalendar(String coupleId) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        AppTheme.fadeSlideRoute(CalendarScreen(coupleId: coupleId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('우리의 연결'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading && _currentUser == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '연결 준비 중...',
                              style: TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ── 두근거리는 하트 위젯 ──
                              ScaleTransition(
                                scale: _heartScale,
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        isDark
                                            ? AppTheme.darkCard
                                            : const Color(0xFFFFF0F5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.2),
                                        blurRadius: 40,
                                        offset: const Offset(0, 12),
                                      ),
                                      BoxShadow(
                                        color: AppTheme.primaryLight
                                            .withOpacity(0.15),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        AppTheme.primaryGradient
                                            .createShader(bounds),
                                    child: const Icon(
                                      Icons.favorite,
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),

                              // ── 감성적인 환영 메시지 ──
                              Text(
                                '서로 연결하여',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppTheme.primaryGradient
                                        .createShader(bounds),
                                child: const Text(
                                  '아름다운 기록을 시작하세요',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),

                              // ── 내 코드 생성 영역 ──
                              if (_myInviteCode == null)
                                _buildGenerateButton()
                              else
                                _buildInviteCodeCard(isDark),

                              const SizedBox(height: 40),

                              // ── 구분선 영역 ──
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: isDark
                                              ? Colors.white12
                                              : const Color(0xFFEBEBEB),
                                          thickness: 1)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      '또는 코드로 연결',
                                      style: TextStyle(
                                        color: AppTheme.textHint,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: isDark
                                              ? Colors.white12
                                              : const Color(0xFFEBEBEB),
                                          thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // ── 파트너 코드 입력 인터페이스 ──
                              _buildCodeInput(isDark),
                              const SizedBox(height: 24),

                              _buildConnectButton(),
                              const SizedBox(height: 32),

                              // ── 보조 액션 (솔로 모드) ──
                              TextButton(
                                onPressed: _isLoading ? null : _startSolo,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.textHint,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: const Text(
                                  '상대방 없이 혼자 시작하기',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFFA0A0B0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
              ),
              // 하단 배너 광고 영역
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  /// 초대 코드 생성 버튼 빌더
  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generateCode,
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: const Text('내 초대 코드 생성하기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  /// 생성된 초대 코드를 크고 아름답게 보여주는 카드 위젯 빌더
  Widget _buildInviteCodeCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCard.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.white,
          width: 2,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link, size: 16, color: AppTheme.textHint),
              SizedBox(width: 6),
              Text(
                '상대방에게 이 코드를 알려주세요',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 48), // 복사 아이콘과 중앙 정렬을 맞추기 위한 여백
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  _myInviteCode!,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 10,
                  ),
                ),
              ),
              // 복사 버튼
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  onTap: _copyCode,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.copy_rounded,
                        size: 22, color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 파트너 코드를 입력받는 텍스트 필드 빌더
  Widget _buildCodeInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: TextField(
        controller: _codeController,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
        ),
        decoration: const InputDecoration(
          hintText: '여기에 코드 입력',
          hintStyle: TextStyle(
            letterSpacing: 0,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textHint,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.tag, color: AppTheme.textHint, size: 20),
          ),
        ),
        keyboardType: TextInputType.text,
        inputFormatters: [
          LengthLimitingTextInputFormatter(8), // 8자리 제한
        ],
      ),
    );
  }

  /// 최종 연결 실행 버튼 빌더
  Widget _buildConnectButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _connect,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link, size: 20),
                  SizedBox(width: 8),
                  Text('연결 시작하기'),
                ],
              ),
      ),
    );
  }
}
