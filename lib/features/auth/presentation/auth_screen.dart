import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/ad_banner_widget.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _codeController = TextEditingController();
  UserModel? _currentUser;
  String? _myInviteCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _preSignIn();
  }

  void _preSignIn() async {
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.signInAnonymously();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
    
    // 이미 커플에 연결되어 있다면 바로 이동
    if (user?.coupleId != null) {
      _navigateToCalendar(user!.coupleId!);
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

  void _connect() async {
    if (_currentUser == null || _codeController.text.length != 6) return;
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final success = await repo.connectWithCode(_currentUser!.uid, _codeController.text);
    
    if (success) {
      // 갱신된 사용자 정보를 다시 가져와서 coupleId 확인
      final updatedUser = await repo.signInAnonymously();
      if (updatedUser?.coupleId != null) {
        _navigateToCalendar(updatedUser!.coupleId!);
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('잘못된 코드이거나 연결에 실패했습니다.')),
        );
      }
    }
  }

  void _navigateToCalendar(String coupleId) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CalendarScreen(coupleId: coupleId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('우리의 연결')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _currentUser == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, size: 80, color: Color(0xFFFF85A1)),
                        const SizedBox(height: 24),
                        const Text(
                          '서로 연결하여\n아름다운 기록을 시작하세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4A4A),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 50),
                        if (_myInviteCode == null)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _generateCode,
                            child: const Text('내 초대 코드 생성하기'),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '상대방에게 이 코드를 보내주세요',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _myInviteCode!,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF85A1),
                                    letterSpacing: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 48),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('또는', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                          decoration: const InputDecoration(
                            hintText: '상대방 코드 6자리',
                            hintStyle: TextStyle(letterSpacing: 0, fontSize: 15, fontWeight: FontWeight.normal),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _connect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB3C1),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('연결하기'),
                        ),
                      ],
                    ),
                  ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
