import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  UserModel? _currentUser;
  String? _myInviteCode;
  bool _isLoading = false;

  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late AnimationController _heartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();

    // 진입 페이드 애니메이션
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // 하트 맥박 애니메이션
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
    _preSignIn();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _heartController.dispose();
    _codeController.dispose();
    super.dispose();
  }

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

      // 이미 커플에 연결되어 있다면 바로 이동
      if (user?.coupleId != null) {
        _navigateToCalendar(user!.coupleId!);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  void _startSolo() async {
    setState(() => _isLoading = true);
    try {
      // 아직 로그인이 안 되어 있으면 먼저 로그인 시도
      if (_currentUser == null) {
        final repo = ref.read(authRepositoryProvider);
        final user = await repo.signInAnonymously();
        if (!mounted) return;
        if (user == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('로그인에 실패했습니다. 다시 시도해주세요.'),
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

  void _connect() async {
    if (_currentUser == null || _codeController.text.length != 6) return;
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final success = await repo.connectWithCode(
        _currentUser!.uid, _codeController.text);

    if (success) {
      final updatedUser = await repo.signInAnonymously();
      if (updatedUser?.coupleId != null) {
        _navigateToCalendar(updatedUser!.coupleId!);
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('잘못된 코드이거나 연결에 실패했습니다.'),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

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
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
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
                              // ── 펄싱 하트 아이콘 ──
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

                              // ── 메인 타이틀 ──
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

                              // ── 초대 코드 생성 / 표시 ──
                              if (_myInviteCode == null)
                                _buildGenerateButton()
                              else
                                _buildInviteCodeCard(isDark),

                              const SizedBox(height: 40),

                              // ── 구분선 ──
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: isDark
                                              ? Colors.white12
                                              : const Color(0xFFEBEBEB),
                                          thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
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

                              // ── 코드 입력 필드 ──
                              _buildCodeInput(isDark),
                              const SizedBox(height: 24),

                              // ── 연결 버튼 ──
                              _buildConnectButton(),
                              const SizedBox(height: 32),

                              // ── 솔로 모드 ──
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
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 초대 코드 생성 버튼 ──
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

  // ── 생성된 초대 코드 카드 ──
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 6),
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
              const SizedBox(width: 48),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  onTap: _copyCode,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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

  // ── 코드 입력 필드 ──
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
        decoration: InputDecoration(
          hintText: '여기에 코드 입력',
          hintStyle: TextStyle(
            letterSpacing: 0,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textHint,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(Icons.tag, color: AppTheme.textHint, size: 20),
          ),
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
      ),
    );
  }

  // ── 연결 시작 버튼 ──
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
