import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firestore_repository.dart';
import '../logic/rewards.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// 로그인 상태에 따라 로그인 화면 또는 홈 화면을 보여 줍니다.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.policy});

  final RewardPolicy policy;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return _SignedIn(key: ValueKey(user.uid), user: user, policy: policy);
      },
    );
  }
}

class _SignedIn extends StatefulWidget {
  const _SignedIn({super.key, required this.user, required this.policy});

  final User user;
  final RewardPolicy policy;

  @override
  State<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends State<_SignedIn> {
  late final FirestoreStudyRepository _repo =
      FirestoreStudyRepository(widget.policy, user: widget.user);
  late Future<void> _init = _repo.init();

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('서버에 연결하지 못했어요.\n인터넷 연결을 확인해 주세요.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _init = _repo.init()),
                      child: const Text('다시 시도'),
                    ),
                    TextButton(
                      onPressed: _repo.signOut,
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return HomeScreen(repo: _repo);
      },
    );
  }
}
