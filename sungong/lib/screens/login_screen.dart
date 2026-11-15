import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// 이메일·비밀번호 로그인과 회원가입
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _signUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = FirebaseAuth.instance;
    try {
      if (_signUp) {
        await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _message(e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = '비밀번호를 재설정할 이메일을 먼저 입력해 주세요.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$email 로 비밀번호 재설정 메일을 보냈어요.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _message(e.code));
    }
  }

  static String _message(String code) => switch (code) {
        'invalid-email' => '이메일 형식이 올바르지 않아요.',
        'user-disabled' => '사용이 중지된 계정이에요.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          '이메일 또는 비밀번호가 맞지 않아요.',
        'email-already-in-use' => '이미 가입된 이메일이에요. 로그인해 주세요.',
        'weak-password' => '비밀번호는 6자 이상으로 정해 주세요.',
        'network-request-failed' => '인터넷 연결을 확인해 주세요.',
        'too-many-requests' => '시도가 너무 많아요. 잠시 뒤 다시 해 주세요.',
        'operation-not-allowed' => 'Firebase 콘솔에서 이메일 로그인이 켜져 있지 않아요.',
        _ => '문제가 생겼어요. ($code)',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.timer_rounded, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('순공', textAlign: TextAlign.center, style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  const Text('공부한 시간만큼 포인트가 쌓여요', textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? '이메일을 입력해 주세요.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? '비밀번호는 6자 이상이에요.' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_signUp ? '가입하기' : '로그인', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _signUp = !_signUp;
                              _error = null;
                            }),
                    child: Text(_signUp ? '이미 계정이 있어요 · 로그인' : '처음이에요 · 회원가입'),
                  ),
                  if (!_signUp)
                    TextButton(
                      onPressed: _busy ? null : _resetPassword,
                      child: const Text('비밀번호를 잊었어요'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
