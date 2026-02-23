import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../../core/models/models.dart';

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
      appBar: AppBar(title: const Text('LoveTree 시작하기')),
      body: _isLoading && _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '상대방과 연결하여\n우리만의 달력을 만들어보세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  if (_myInviteCode == null)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _generateCode,
                      child: const Text('내 초대 코드 생성하기'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('상대방에게 이 코드를 알려주세요'),
                          const SizedBox(height: 8),
                          Text(
                            _myInviteCode!,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: '상대방 코드 입력 (6자리)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _connect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('연결하기'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
