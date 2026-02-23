import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _myInviteCode;
  bool _isLoading = false;

  void _generateCode() async {
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final code = await repo.createInviteCode('mock_uid');
    setState(() {
      _myInviteCode = code;
      _isLoading = false;
    });
  }

  void _connect() async {
    if (_codeController.text.length != 6) return;
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final success = await repo.connectWithCode('mock_uid', _codeController.text);
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '연결 성공!' : '잘못된 코드입니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LoveTree 시작하기')),
      body: Padding(
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
                child: Text(
                  '내 코드: $_myInviteCode',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink),
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
                child: const Text('연결하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
