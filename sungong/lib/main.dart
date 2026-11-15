import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/local_repository.dart';
import 'firebase_options.dart';
import 'logic/rewards.dart';
import 'screens/auth_gate.dart';
import 'screens/home_screen.dart';

const policy = RewardPolicy();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = FirebaseConfig.current;
  if (options != null) {
    await Firebase.initializeApp(options: options);
    runApp(const SungongApp(home: AuthGate(policy: policy)));
  } else {
    // Firebase 설정 전: 기기 안에만 저장
    final repo = LocalStudyRepository(policy);
    await repo.load();
    runApp(SungongApp(home: HomeScreen(repo: repo)));
  }
}

class SungongApp extends StatelessWidget {
  const SungongApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '순공',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
